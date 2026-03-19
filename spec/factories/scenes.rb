FactoryBot.define do
  factory :scene do
    game
    sequence(:title) { |n| "Scene #{n}" }
    description { "A scene description" }
    private { false }

    trait :private do
      private { true }
    end

    trait :resolved do
      resolved_at { Time.current }
      resolution { "The scene ended." }
    end

    trait :with_parent do
      association :parent_scene, factory: :scene
    end
  end
end
