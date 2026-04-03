# typed: true

class PostRead < ApplicationRecord
  extend T::Sig

  belongs_to :post
  belongs_to :user

  validates :post_id, uniqueness: { scope: :user_id }

  sig { params(post: Post, user: User).returns(PostRead) }
  def self.mark!(post, user)
    find_or_create_by!(post: post, user: user) do |pr|
      pr.read_at = Time.current
    end
  end
end
