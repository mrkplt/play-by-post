FactoryBot.define do
  factory :page_version do
    page
    association :edited_by, factory: :user
    sequence(:title) { |n| "Page version #{n}" }
    body { "# Heading\n\nVersioned body." }
  end
end
