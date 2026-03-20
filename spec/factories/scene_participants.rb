FactoryBot.define do
  factory :scene_participant do
    scene
    user
    last_visited_at { Time.current }
  end
end
