FactoryBot.define do
  factory :game_key_authorization do
    association :game
    association :user
    feature { "scene_summary" }
  end
end
