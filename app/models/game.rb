class Game < ApplicationRecord
  has_many :game_members, dependent: :destroy
  has_many :users, through: :game_members
  has_many :scenes, dependent: :destroy
  has_many :characters, dependent: :destroy
  has_many :game_files, dependent: :destroy
  has_many :invitations, dependent: :destroy

  validates :name, presence: true, length: { maximum: 200 }

  def game_master
    game_members.find_by(role: "game_master")&.user
  end

  def active_members
    game_members.where(status: "active")
  end

  def member_for(user)
    game_members.find_by(user: user)
  end

  def game_master?(user)
    game_members.exists?(user: user, role: "game_master")
  end

  def active_member?(user)
    game_members.exists?(user: user, status: "active")
  end
end
