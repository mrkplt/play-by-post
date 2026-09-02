FactoryBot.define do
  factory :scene_summary_version do
    scene_summary
    association :edited_by, factory: :user
    body { "Versioned summary body." }
    generated_at { nil }

    trait :ai_generated do
      generated_at { Time.current }
    end
  end
end
