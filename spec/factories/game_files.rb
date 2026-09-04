FactoryBot.define do
  factory :game_file do
    game
    # created_by is NOT NULL (Fizzy #18); default to a fresh user so a bare
    # create(:game_file) is valid. Specs that care about ownership pass their own.
    created_by factory: %i[user]
    sequence(:filename) { |n| "file_#{n}.pdf" }
  end
end
