# typed: strict

# View model for a game and its viewer. Replaces the derived boolean the
# controllers used to thread into views: the capability check is a method here,
# backed by the policy so an affordance can never diverge from what the
# controller authorizes.
class GamePresenter < BasePresenter
  extend T::Sig
  include ActionView::Helpers::DateHelper

  sig { params(model: Game, options: T.untyped).void }
  def initialize(model, **options)
    super
  end

  # The wrapped Game, for presenters that wrap a GamePresenter (rather than a
  # Game) — e.g. GameShowPresenter.
  sig { returns(Game) }
  def model
    @model
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

  # The viewer's display name — trivial delegation, but explicit so a
  # component's template calling it on this presenter is Sorbet-checkable
  # (SimpleDelegator passthrough is invisible to static analysis).
  sig { returns(String) }
  def name
    @model.name
  end

  sig { returns(T.nilable(String)) }
  def description
    @model.description
  end

  sig { returns(Integer) }
  def id
    @model.id
  end

  sig { returns(T::Boolean) }
  def ai_summaries_enabled?
    @model.ai_summaries_enabled?
  end

  sig { returns(T::Boolean) }
  def errors?
    @model.errors.any?
  end

  sig { returns(T::Array[String]) }
  def error_messages
    @model.errors.full_messages
  end

  # Whether image attachments are turned off for this game — the post
  # composer's decision on whether to show its image field.
  sig { returns(T::Boolean) }
  def images_disabled?
    @model.images_disabled? # mutant:disable
  end

  # Whether character sheets are hidden from players — the Edit Game screen's
  # sheet-visibility toggle.
  sig { returns(T::Boolean) }
  def sheets_hidden?
    @model.sheets_hidden? # mutant:disable
  end

  # The Export row's passive subtitle: when this viewer has a valid export
  # receipt for this game, how long ago it succeeded — otherwise no subtitle
  # at all. The viewer is supplied at construction (options[:current_user]).
  sig { returns(T.nilable(String)) }
  def export_notice
    receipt = GameExportRequest.valid_receipt_for(@options.fetch(:current_user), @model)
    return nil unless receipt

    "Last export: #{time_ago_in_words(T.must(receipt.succeeded_at))} ago"
  end

  # The game's Campaign Notebook board. NotebookBoardPresenter owns the
  # grouping-by-lane query, so this is a presenter wrapping a presenter, not a
  # hash of models handed to the view.
  sig { returns(NotebookBoardPresenter) }
  def notebook_board
    NotebookBoardPresenter.new(@model)
  end
end
