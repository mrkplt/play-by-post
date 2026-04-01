# typed: true

class Game < ApplicationRecord
  extend T::Sig

  POST_EDIT_WINDOW_OPTIONS = [
    [ "Forever", nil ],
    [ "10 minutes", 10 ],
    [ "30 minutes", 30 ],
    [ "1 hour", 60 ],
    [ "1 day", 1440 ],
    [ "1 week", 10080 ]
  ].freeze

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

  sig { returns(T.nilable(ActiveSupport::Duration)) }
  def edit_window_duration
    return nil if post_edit_window_minutes.nil?

    post_edit_window_minutes.minutes
  end
end
