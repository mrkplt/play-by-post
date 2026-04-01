FactoryBot.define do
  factory :post_read do
    post
    user
    read_at { Time.current }
  end
end
