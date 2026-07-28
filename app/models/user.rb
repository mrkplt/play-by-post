# typed: true

class User < ApplicationRecord
  extend T::Sig

  devise :magic_link_authenticatable, :rememberable

  has_one :user_profile, dependent: :destroy
  has_many :game_members, dependent: :destroy
  has_many :games, through: :game_members
  has_many :scene_participants, dependent: :destroy
  has_many :scenes, through: :scene_participants
  has_many :posts, dependent: :destroy
  has_many :characters, dependent: :destroy
  has_one :rss_token, dependent: :destroy

  sig { returns(T.nilable(String)) }
  def display_name
    user_profile&.display_name
  end
end
