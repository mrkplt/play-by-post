FactoryBot.define do
  factory :feedback do
    user
    body { "The scene composer is great, but the post editor could use undo." }
    url { "https://example.com/games/1" }
  end
end
