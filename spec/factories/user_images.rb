FactoryBot.define do
  factory :user_image do
    user

    trait :with_file do
      after(:build) do |image|
        image.file.attach(
          io: File.open(Rails.root.join("spec/fixtures/files/test_image.png")),
          filename: "avatar.png",
          content_type: "image/png"
        )
      end
    end

    trait :current do
      current { true }
    end
  end
end
