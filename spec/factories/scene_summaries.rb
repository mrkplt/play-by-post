FactoryBot.define do
  factory :scene_summary do
    scene
    sequence(:body) { |n| "Summary body #{n}" }
    generated_at { nil }
    edited_at { nil }
    edited_by { nil }

    trait :ai_generated do
      generated_at { Time.current }
    end

    trait :edited do
      edited_at { Time.current }
      association :edited_by, factory: :user
    end
  end
end
