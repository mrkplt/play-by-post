FactoryBot.define do
  factory :notebook_entry do
    game
    sequence(:title) { |n| "Notebook Entry #{n}" }
    body { "# Idea\n\nSome **markdown** body." }
    status { "new" }
  end
end
