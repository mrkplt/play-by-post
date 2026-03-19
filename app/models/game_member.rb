class GameMember < ApplicationRecord
  belongs_to :game
  belongs_to :user

  ROLES = %w[game_master player].freeze
  STATUSES = %w[active removed banned].freeze

  validates :role, inclusion: { in: ROLES }
  validates :status, inclusion: { in: STATUSES }

  scope :active, -> { where(status: "active") }
  scope :game_masters, -> { where(role: "game_master") }
  scope :players, -> { where(role: "player") }

  def game_master?
    role == "game_master"
  end

  def active?
    status == "active"
  end

  def removed?
    status == "removed"
  end

  def banned?
    status == "banned"
  end
end
