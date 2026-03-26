FactoryBot.define do
  factory :game_file do
    game
    sequence(:filename) { |n| "file_#{n}.pdf" }
  end
end
