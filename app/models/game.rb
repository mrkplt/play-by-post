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

  # MAINTENANCE: GamePurgeJob does NOT rely on these dependent: cascades to
  # delete a purged game's records and artifacts — it collects and deletes them
  # explicitly, child-first. Adding a new association here (or a new attachment
  # to any record below a game) means GamePurgeJob#delete_records /
  # #purge_artifacts must be updated too, or those rows/blobs will be orphaned
  # when a game is purged. The end-to-end spec in spec/jobs/game_purge_job_spec.rb
  # is the guardrail: populate the new record there so a missed table fails.
  has_many :game_members, dependent: :destroy
  has_many :users, through: :game_members
  has_many :scenes, dependent: :destroy
  has_many :characters, dependent: :destroy
  has_many :game_files, dependent: :destroy
  has_many :pages, dependent: :destroy
  has_many :game_links, dependent: :destroy
  has_many :notebook_entries, dependent: :destroy
  has_many :invitations, dependent: :destroy
  has_many :api_tokens, dependent: :destroy
  # No dependent: cascade — GamePurgeJob collects and deletes a purged game's
  # export requests (and their archive blobs) explicitly.
  has_many :game_export_requests # rubocop:disable Rails/HasManyOrHasOneDependent

  validates :name, presence: true, length: { maximum: 200 }

  # Soft-deleted games are hidden everywhere by this default scope: every
  # controller lookup, through-association, and export enumeration is filtered
  # without touching each call site. The purge sweep/job read via `unscoped` to
  # see them again. Deletion is a two-phase flow — see REQUIREMENTS "Game
  # Deletion": the GM soft-deletes (sets deleted_at), and after a retention
  # window GamePurgeSweepJob enqueues GamePurgeJob to destroy the record and all
  # its artifacts.
  default_scope { where(deleted_at: nil) }

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

  # Game master, active player, or removed (former) player — everyone
  # except a banned member or a non-member.
  sig { params(user: User).returns(T::Boolean) }
  def viewable_by?(user)
    membership = member_for(user)
    return false unless membership

    membership.game_master? || membership.active? || membership.removed?
  end

  # Phase one of deletion: hide the game now. The record and its artifacts are
  # removed later by GamePurgeJob once the retention window has passed.
  sig { void }
  def soft_delete!
    update!(deleted_at: Time.current)
  end

  sig { returns(T::Boolean) }
  def deleted?
    deleted_at.present?
  end

  sig { returns(T.nilable(ActiveSupport::Duration)) }
  def edit_window_duration
    minutes = post_edit_window_minutes
    return nil if minutes.nil?

    minutes.minutes
  end
end
