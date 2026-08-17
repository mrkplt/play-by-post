FactoryBot.define do
  factory :notebook_entry_version do
    notebook_entry
    association :edited_by, factory: :user
    sequence(:title) { |n| "Notebook entry version #{n}" }
    body { "# Heading\n\nVersioned body." }
  end
end
