FactoryBot.define do
  factory :content_template do
    game
    content_type { "page" }
    body { "# Template\n\nStart here." }
  end
end
