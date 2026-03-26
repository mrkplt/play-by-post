FactoryBot.define do
  factory :notification_preference do
    scene
    user
    muted { true }
  end
end
