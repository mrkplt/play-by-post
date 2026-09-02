# typed: strict

# View model for a scene summary. The summary's game, url_helpers and (where a
# write affordance is shown) policy are supplied at construction
# (options[:game] / options[:urls] / options[:policy]) rather than looked up
# or rebuilt in a component, so the paths and capability answers below are the
# only place that knows how to build them.
class SceneSummaryPresenter < BasePresenter
  extend T::Sig
  include Draftable::Presentation

  # Build a presenter for broadcasting a finished summary to one visibility
  # class (SceneSummaryVisibility). A broadcast has no request and no single
  # viewer — it goes to everyone in a class — so the two per-viewer facts the
  # summary component reads (can it be managed, is the AI badge loud) are fixed
  # by the class rather than derived from a User/policy: only the `manager` class
  # manages, and only the `hidden` class would suppress the badge but it never
  # receives an AI summary at all, so every broadcast class shows the badge. URLs
  # come from the app's route helpers rather than a controller.
  sig { params(summary: SceneSummary, klass: Symbol, game: Game).returns(SceneSummaryPresenter) }
  def self.for_broadcast(summary, klass:, game:)
    new(
      summary,
      game: game,
      urls: Rails.application.routes.url_helpers,
      can_manage: klass == SceneSummaryVisibility::MANAGER,
      show_ai_badge: true
    )
  end

  sig { returns(String) }
  # mutant:disable
  def status_label
    edited = @model.edited?
    # AI provenance is sticky (Fizzy #122): a hand-edit no longer erases it, so an
    # AI-generated summary that was then edited must still read as AI-generated —
    # surfacing both facts rather than collapsing to "Edited".
    return edited ? "AI-generated · edited" : "AI-generated" if @model.ai_generated?

    edited ? "Edited" : "Hand-written"
  end

  sig { returns(T.nilable(String)) }
  # mutant:disable
  def formatted_generated_at
    (generated_at = @model.generated_at) && generated_at.strftime("%b %-d, %Y")
  end

  sig { returns(T.nilable(String)) }
  # mutant:disable
  def formatted_edited_at
    (edited_at = @model.edited_at) && edited_at.strftime("%b %-d, %Y")
  end

  sig { returns(T::Boolean) }
  # mutant:disable
  def ai_generated?
    @model.ai_generated?
  end

  # The AI Control Plane's per-viewer DISPLAY preference: whether the
  # prominent "AI-generated" badge should render for the viewer supplied at
  # construction (options[:viewer]). Provenance (#status_label/#ai_generated?)
  # is always available regardless — this only controls loudness. A viewer
  # with no profile yet (never visited Profile) gets the enum's own default,
  # "tagged", via UserProfile#ai_display_preference; a nil viewer (no options
  # threaded through, e.g. specs that don't care) also defaults to tagged so
  # the badge shows unless a caller opts a real viewer into something quieter.
  sig { returns(T::Boolean) }
  def show_ai_badge?
    return true unless ai_generated?

    return @options.fetch(:show_ai_badge) if @options.key?(:show_ai_badge)

    !@options.fetch(:viewer, nil)&.user_profile&.shown?
  end

  sig { returns(T::Boolean) }
  # mutant:disable
  def edited?
    @model.edited?
  end

  sig { returns(T::Boolean) }
  def persisted?
    @model.persisted?
  end

  sig { returns(ActiveModel::Errors) }
  def errors
    @model.errors
  end

  sig { returns(String) }
  def scene_title
    @model.scene.title
  end

  sig { returns(T.nilable(String)) }
  # mutant:disable
  def formatted_scene_resolved_at
    resolved = @model.scene.resolved_at
    return nil unless resolved

    resolved.strftime("%b %-d, %Y")
  end

  # The viewer may edit or delete this summary — asked of the policy supplied
  # at construction (options[:policy]) rather than looked up here. A broadcast,
  # which has no policy, fixes this by visibility class via options[:can_manage].
  sig { returns(T::Boolean) }
  def can_manage?
    return @options.fetch(:can_manage) if @options.key?(:can_manage)

    @options.fetch(:policy).manage?
  end

  sig { returns(T.untyped) }
  # mutant:disable
  def body
    @model.body
  end

  # The scene's resolved-at timestamp in RFC 2822 form, for an RSS item's
  # <pubDate> — nil when the scene (unusually, for a public summary) has no
  # resolved_at.
  sig { returns(T.nilable(String)) }
  # mutant:disable
  def scene_resolved_at_pub_date
    resolved = @model.scene.resolved_at
    return nil unless resolved

    resolved.rfc2822
  end

  # A presenter for this summary's screen/feed URLs, built from the same
  # game/urls this presenter was constructed with — split out to keep this
  # class under the project's method ceiling.
  sig { returns(SceneSummaryRoutesPresenter) }
  def routes
    SceneSummaryRoutesPresenter.new(@model, game: @options.fetch(:game), urls: @options.fetch(:urls))
  end
end
