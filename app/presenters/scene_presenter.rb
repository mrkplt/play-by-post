# typed: strict

class ScenePresenter < BasePresenter
  extend T::Sig

  sig { params(model: Scene, options: T.untyped).void }
  def initialize(model, **options)
    super
  end

  # The wrapped Scene, for presenters that wrap a ScenePresenter (rather than
  # a Scene) and need the raw model — e.g. SceneCardPresenter, ScenePostsPresenter.
  sig { returns(Scene) }
  def model
    @model
  end

  # Whether this scene has activity since the viewer last logged in — the
  # game-view card's attention glow. `hot_scene_ids` (options[:hot_scene_ids])
  # is supplied at construction rather than computed here.
  sig { returns(T::Boolean) }
  def hot?
    @options.fetch(:hot_scene_ids, Set.new).include?(@model.id)
  end

  sig { returns(String) }
  def title
    @model.title
  end

  # Reads status_label rather than testing resolved? directly, so the
  # scene's resolved-state is decided in exactly one place (status_label)
  # and every other display derives from that single canonical value.
  sig { returns(String) }
  def parent_option_label
    return title if status_label == "Active"

    "#{title} (#{status_label})"
  end

  # Whether the scene currently carries validation errors — the New Scene /
  # Quick Scene form's re-render after a failed #create reads this instead of
  # a component reaching into @model.errors directly.
  sig { returns(T::Boolean) }
  def errors?
    @model.errors.any?
  end

  sig { returns(T::Array[String]) }
  def error_messages
    @model.errors.full_messages
  end

  sig { returns(String) }
  def status_label
    resolved? ? "Resolved" : "Active"
  end

  sig { returns(T::Boolean) }
  def resolved?
    @model.resolved? # mutant:disable
  end

  # Pre-computed label/variant pairs for Shared::StatusBadgeRowComponent, for
  # the scene screen's meta row: Private and Resolved, each shown only when
  # true (no badge at all for an ordinary public, active scene).
  sig { returns(T::Array[Shared::StatusBadgeRowComponent::Badge]) }
  def status_badges
    badges = T.let([], T::Array[Shared::StatusBadgeRowComponent::Badge])
    badges << { label: "Private", variant: :yellow } if @model.private?
    badges << { label: "Resolved", variant: :gray } if status_label == "Resolved"
    badges
  end

  sig { returns(String) }
  def participant_names
    @model.scene_participants
      .includes(:character, :user)
      .map(&:display_name)
      .join(", ")
  end

  # "N participants" — the only meta a scene card shows in the redesign.
  sig { returns(String) }
  def participant_summary
    count = @model.scene_participants.count
    "#{count} #{count == 1 ? 'participant' : 'participants'}"
  end

  sig { returns(String) }
  def formatted_created_at
    @model.created_at.strftime("%b %-d, %Y %l:%M%P")
  end

  # The GM-facing resolution text shown once a scene is resolved, or nil when
  # there is none — named for what it shows rather than delegated to raw
  # `resolution`, so the presenter (not the component) owns reading it off
  # the model. `nil` (not blank-string) doubles as the template's presence
  # gate, via `<% if (resolution = @scene_presenter.resolution) %>`.
  sig { returns(T.nilable(String)) }
  def resolution
    @model.resolution.presence
  end

  # A presenter for this scene's "End Scene" / composer draft URLs, built from
  # the same game/urls this presenter was constructed with — split out to
  # keep this class under the project's method ceiling.
  sig { returns(SceneRoutesPresenter) }
  def routes
    SceneRoutesPresenter.new(@model, game: @options.fetch(:game), urls: @options.fetch(:urls))
  end
end
