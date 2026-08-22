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

  # The memberships that back a person's profile section listings (feeds, API
  # tokens, key contributions): every non-banned membership, game preloaded,
  # ordered by game name. One source for the shared "your games" ordering.
  scope :for_profile_listing, -> { where.not(status: "banned").includes(:game).order("games.name") }

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

  # Game master, active player, or removed (former) player — everyone
  # except a banned member.
  sig { returns(T::Boolean) }
  def viewable?
    game_master? || active? || removed?
  end
end
