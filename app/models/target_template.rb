class TargetTemplate < ActiveRecord::Base
  belongs_to :assigner, class_name: 'Faculty'

  mount_uploader :rubric, RubricUploader

  # ensure required fields for a target (which cannot be auto-alloted) are specified
  validates_presence_of :role, :title, :description

  validates_presence_of :assigner_id, if: :populate_on_start?

  def due_date(batch: Batch.current_or_last)
    (batch.start_date + days_from_start).to_date
  end

  # Create a target using this template.
  def create_target!(startup)
    Target.create!(
      startup: startup,
      status: Target::STATUS_PENDING,
      role: role,
      title: title,
      description: description,
      assigner: assigner,
      resource_url: resource_url,
      completion_instructions: completion_instructions,
      due_date: due_date.end_of_day,
      slideshow_embed: slideshow_embed
    )
  end
end
