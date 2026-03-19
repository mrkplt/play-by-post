FactoryBot.define do
  factory :post do
    scene
    user
    content { "A post in the scene." }
    is_ooc { false }

    trait :ooc do
      is_ooc { true }
    end

    trait :edited do
      last_edited_at { Time.current }
    end
  end
end
