# typed: strict

# View model for a game and its viewer. Replaces the derived boolean the
# controllers used to thread into views: the capability check is a method here,
# backed by the policy so an affordance can never diverge from what the
# controller authorizes.
class GamePresenter < BasePresenter
  extend T::Sig

  sig { params(model: Game, options: T.untyped).void }
  def initialize(model, **options)
    super
  end

  # The viewer may administer this game. A capability, not a role: it asks the
  # policy's `manage?` rather than `update?` (which means "this row may be
  # modified") so the view layer never hard-codes who currently qualifies.
  # The policy is supplied at construction (options[:policy]) rather than
  # built here, so a capability rename is chased through one call site
  # instead of every presenter that asks the question.
  sig { returns(T::Boolean) }
  def can_manage?
    @options.fetch(:policy).manage?
  end

  # Outstanding (unaccepted) invitations for this game, newest first — the data
  # behind the GM-only invite panel on the Roster tab.
  sig { returns(T::Array[Invitation]) }
  def pending_invitations
    @model.invitations.pending.order(created_at: :desc).to_a
  end

  # The game's pages, alphabetised by title — the data behind the Pages tab.
  sig { returns(T::Array[Page]) }
  def pages
    @model.pages.order(:title).to_a
  end

  # The game's links, newest first — the data behind the Links tab.
  sig { returns(T::Array[GameLink]) }
  def links
    @model.game_links.order(created_at: :desc).to_a
  end

  # The game's notebook entries, grouped by kanban lane (oldest first within
  # each lane) — the data behind the GM-only Notebook tab's board.
  sig { returns(T::Hash[String, T::Array[NotebookEntry]]) }
  def notebook_entries
    @model.notebook_entries.order(:created_at).to_a.group_by(&:status)
  end

  # Whether image attachments are turned off for this game — the post
  # composer's decision on whether to show its image field.
  sig { returns(T::Boolean) }
  def images_disabled?
    @model.images_disabled? # mutant:disable
  end
end
