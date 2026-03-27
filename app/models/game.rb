# typed: true

class Game < ApplicationRecord
  extend T::Sig

  has_many :game_members, dependent: :destroy
  has_many :users, through: :game_members
  has_many :scenes, dependent: :destroy
  has_many :characters, dependent: :destroy
  has_many :game_files, dependent: :destroy
  has_many :invitations, dependent: :destroy

  validates :name, presence: true, length: { maximum: 200 }

  sig { returns(T.nilable(User)) }
  def game_master
    game_members.find_by(role: "game_master")&.user
  end

  sig { returns(T.untyped) }
  def active_members
    game_members.where(status: "active")
  end

  sig { params(user: User).returns(T.nilable(GameMember)) }
  def member_for(user)
    game_members.find_by(user: user)
  end

  sig { params(user: User).returns(T::Boolean) }
  def game_master?(user)
    game_members.exists?(user: user, role: "game_master")
  end

  sig { params(user: User).returns(T::Boolean) }
  def active_member?(user)
    game_members.exists?(user: user, status: "active")
  end
end
