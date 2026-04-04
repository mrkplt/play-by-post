# typed: true

class GameMember < ApplicationRecord
  extend T::Sig

  belongs_to :game
  belongs_to :user

  ROLES = %w[game_master player].freeze
  STATUSES = %w[active removed banned].freeze

  validates :role, inclusion: { in: ROLES }
  validates :status, inclusion: { in: STATUSES }

  scope :active, -> { where(status: "active") }
  scope :game_masters, -> { where(role: "game_master") }
  scope :players, -> { where(role: "player") }

  sig { returns(T::Boolean) }
  def game_master?
    role == "game_master"
  end

  sig { returns(T::Boolean) }
  def active?
    status == "active"
  end

  sig { returns(T::Boolean) }
  def removed?
    status == "removed"
  end

  sig { returns(T::Boolean) }
  def banned?
    status == "banned"
  end
end
