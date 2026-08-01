# typed: true

class Character < ApplicationRecord
  extend T::Sig

  belongs_to :game
  belongs_to :user
  has_many :character_versions, dependent: :destroy

  validates :name, presence: true

  scope :active, -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }

  sig { returns(T::Boolean) }
  def archived?
    archived_at.present?
  end

  sig { void }
  def archive!
    update!(archived_at: Time.current)
  end

  # Which visibility rule applies to this viewer. Pure decision, no query — the
  # scope below is the only part that touches the database, so the branching can
  # be tested directly.
  sig { params(viewer: User, game: Game).returns(Symbol) }
  def self.visibility_rule(viewer, game)
    return :all if game.game_master?(viewer)
    return :own_only if game.sheets_hidden?

    :unhidden_or_own
  end

  scope :visible_to, ->(viewer, game) {
    case Character.visibility_rule(viewer, game)
    when :all then all
    when :own_only then where(user: viewer)
    else where(hidden: false).or(where(user: viewer))
    end
  }

  sig { params(user: User, game: Game).returns(T::Boolean) }
  def editable_by?(user, game)
    self.user == user || game.game_master?(user)
  end

  # Snapshotting is an explicit consequence of saving rather than an after_save
  # callback, so the behaviour is readable at the definition instead of in a
  # callback chain. save/save! are the only paths that need overriding: create
  # and update route through save, create!/update! through save!, and
  # touch/update_column bypass both — exactly as after_save did.
  #
  # super is wrapped in the transaction so a failed snapshot still rolls the
  # character back, which is what running inside the callback chain gave us.
  sig { params(options: T.untyped).returns(T.untyped) }
  def save(**options)
    transaction { super.tap { |saved| snapshot_version if saved } }
  end

  sig { params(options: T.untyped).returns(T.untyped) }
  def save!(**options)
    transaction { super.tap { snapshot_version } }
  end

  # The version row this character's current state should produce. Pure — the
  # snapshot writes exactly what this returns, so attribution (Current.user
  # falling back to the owner) can be tested without saving anything.
  sig { returns(T::Hash[Symbol, T.untyped]) }
  def version_attributes
    {
      content: content.to_s,
      edited_by_id: Current.user&.id || user_id
    }
  end

  private

  def snapshot_version
    character_versions.create!(version_attributes)
  end
end
