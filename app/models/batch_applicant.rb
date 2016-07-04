class BatchApplicant < ActiveRecord::Base
  has_and_belongs_to_many :batch_applications
  has_many :applications_as_lead, class_name: 'BatchApplication', foreign_key: 'team_lead_id'

  # Per-founder application fee.
  APPLICATION_FEE = 1000
  NUMBER_OF_APPLICATIONS_PER_FEE = 4

  # Basic validations.
  validates :email, presence: true, uniqueness: true

  # Custom validations.
  validate :email_must_look_right

  def email_must_look_right
    errors[:email] << "doesn't look like an email" unless email =~ /\S+@\S+/
  end

  has_secure_token

  # Attempts to find an applicant with the supplied token.
  def self.find_using_token(incoming_token)
    applicant = find_by token: incoming_token

    return if applicant.blank?

    # Hack to continue logins that were created before time-bound check was introduced.
    applicant.update!(sign_in_email_sent_at: Time.now) if applicant.sign_in_email_sent_at.blank?

    # Don't sign in applicant if the email was sent over an hour ago.
    return if applicant.sign_in_email_sent_at < 1.hour.ago

    applicant
  end

  def applied_to?(batch)
    return false unless batch_applications.present?

    batch_applications.find_by(batch_id: batch.id).present?
  end

  def send_sign_in_email(application_batch)
    # Create a new token.
    regenerate_token

    # Send email.
    BatchApplicantMailer.sign_in(email, token, application_batch).deliver_later

    # Mark when email was sent.
    update!(sign_in_email_sent_at: Time.now)
  end
end
