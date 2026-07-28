FactoryBot.define do
  factory :scene_summary do
    scene
    sequence(:body) { |n| "Summary body #{n}" }
    model_used { nil }
    generated_at { nil }
    input_tokens { nil }
    output_tokens { nil }
    edited_at { nil }
    edited_by { nil }

    trait :ai_generated do
      model_used { "openai/gpt-4o" }
      generated_at { Time.current }
      input_tokens { 500 }
      output_tokens { 150 }
    end

    trait :edited do
      edited_at { Time.current }
      association :edited_by, factory: :user
    end
  end
end
