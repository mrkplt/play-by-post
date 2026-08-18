FactoryBot.define do
  factory :character_image do
    character

    trait :with_file do
      after(:build) do |image|
        image.file.attach(
          io: File.open(Rails.root.join("spec/fixtures/files/test_image.png")),
          filename: "portrait.png",
          content_type: "image/png"
        )
      end
    end

    trait :current do
      current { true }
    end
  end
end
