require 'reform/form/coercion'

class ApplicationStageOneForm < Reform::Form
  include Coercion

  property :application_page_read, virtual: true, validates: { acceptance: true }
  property :team_lead_consent, virtual: true, validates: { acceptance: true }
  property :fees_consent, virtual: true, validates: { acceptance: true }
  properties :university_id, :college, :state, :team_achievement, validates: { presence: true }
  property :cofounder_count, virtual: true, type: Integer, validates: { inclusion: [2, 3, 4] }

  property :team_lead do
    properties :name, :phone, validates: { presence: true }
    property :email, writeable: false
    property :gender, validates: { presence: true, inclusion: Founder.valid_gender_values }
    property :role, validates: { inclusion: Founder.valid_roles }
  end

  collection :cofounders, populate_if_empty: BatchApplicant do
    property :email, validates: { presence: true }
    property :name, validates: { presence: true }
    property :role, validates: { inclusion: Founder.valid_roles }
  end

  # Custom validations.
  validate :prevent_cofounder_duplicates
  validate :cofounder_count_must_be_valid
  validate :emails_must_look_right
  validate :phone_number_must_look_right

  def prevent_cofounder_duplicates
    cofounders.each_with_index do |cofounder, index|
      cofounders[index].errors[:email] << 'is a duplicate of team lead' if cofounder.email == team_lead.email
    end

    previous_cofounder_emails = []

    cofounders.each_with_index do |cofounder, index|
      cofounders[index].errors[:email] << 'has been mentioned previously' if cofounder.email.in?(previous_cofounder_emails)
      previous_cofounder_emails << cofounder.email
    end
  end

  def cofounder_count_must_be_valid
    return if cofounders.count.in? [2, 3, 4]
    errors[:base] << 'Must have at least two, and at most four co-founders.'
  end

  def emails_must_look_right
    cofounders.each_with_index do |cofounder, index|
      cofounders[index].errors[:email] << "doesn't look like an email" unless valid_email?(cofounder.email)
    end
  end

  def phone_number_must_look_right
    team_lead.errors[:phone] << 'must be a 10-digit phone number' unless team_lead.phone =~ /\A[0-9]{10}\z/
  end

  def valid_email?(email)
    email =~ /\S+@\S+/
  end

  def prepopulate!(options)
    self.team_lead = options[:team_lead]
    self.cofounders = [BatchApplicant.new] * 2
    self.cofounder_count = 2
  end

  def save
    BatchApplication.transaction do
      create_application
      update_team_lead
      create_cofounders
    end
  end

  def create_application
    model.update!(
      university_id: university_id,
      team_achievement: team_achievement,
      college: college,
      state: state,
      team_lead_id: team_lead.id,
      phone: team_lead.phone
    )
  end

  def update_team_lead
    team_lead.model.update!(
      name: team_lead.name,
      gender: team_lead.gender,
      role: team_lead.role
    )

    model.batch_applicants << team_lead.model
  end

  def create_cofounders
    cofounders.each do |cofounder|
      applicant = BatchApplicant.find_or_initialize_by(email: cofounder.email)

      applicant.update!(
        name: cofounder.name,
        role: cofounder.role
      )

      model.batch_applicants << applicant
    end
  end
end
