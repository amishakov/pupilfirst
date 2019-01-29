FactoryBot.define do
  factory :target do
    initialize_with { key.present? ? Target.where(key: key).first_or_initialize(attributes) : Target.new(attributes) }

    title { Faker::Lorem.words(6).join ' ' }
    role { Target.valid_roles.sample }
    description { Faker::Lorem.words(200).join ' ' }
    target_action_type { Target.valid_target_action_types.sample }
    days_to_complete { session_at.present? ? nil : rand(1..60) }
    target_group
    faculty { create :faculty, category: Faculty::CATEGORY_TEAM }
    sequence(:sort_index)
    key { nil }
    session_at { nil }

    trait :archived do
      safe_to_archive { true }
      archived { true }
    end

    trait :session do
      session_at { 1.week.from_now }
      days_to_complete { nil }
    end

    trait :for_founders do
      role { Target::ROLE_FOUNDER }
    end

    trait :for_startup do
      role { Target::ROLE_TEAM }
    end

    trait :with_rubric do
      rubric { Rack::Test::UploadedFile.new(Rails.root.join('spec', 'support', 'uploads', 'resources', 'pdf-sample.pdf')) }
    end

    trait(:admissions_cofounder_addition) do
      key { Target::KEY_COFOUNDER_ADDITION }
      role { Target::ROLE_TEAM }
      prerequisite_targets { [create(:target, :admissions_screening)] }
    end

    trait(:admissions_screening) do
      key { Target::KEY_SCREENING }
      role { Target::ROLE_TEAM }
    end

    trait(:admissions_attend_interview) do
      role { Target::ROLE_TEAM }
      key { Target::KEY_ATTEND_INTERVIEW }
      prerequisite_targets { [create(:target, :admissions_cofounder_addition)] }
    end
  end
end
