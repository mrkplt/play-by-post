# typed: strict

# View model for a scene summary. The summary's game, url_helpers and (where a
# write affordance is shown) policy are supplied at construction
# (options[:game] / options[:urls] / options[:policy]) rather than looked up
# or rebuilt in a component, so the paths and capability answers below are the
# only place that knows how to build them.
class SceneSummaryPresenter < BasePresenter
  extend T::Sig

  sig { returns(String) }
  # mutant:disable
  def status_label
    if @model.ai_generated? && @model.edited?
      "Edited"
    elsif @model.ai_generated?
      "AI-generated"
    else
      "Hand-written"
    end
  end

  sig { returns(T.nilable(String)) }
  # mutant:disable
  def formatted_generated_at
    return nil unless @model.generated_at

    @model.generated_at.strftime("%b %-d, %Y")
  end

  sig { returns(T.nilable(String)) }
  # mutant:disable
  def formatted_edited_at
    return nil unless @model.edited_at

    @model.edited_at.strftime("%b %-d, %Y")
  end

  sig { returns(T::Boolean) }
  # mutant:disable
  def ai_generated?
    @model.ai_generated?
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
  # at construction (options[:policy]) rather than looked up here.
  sig { returns(T::Boolean) }
  def can_manage?
    @options.fetch(:policy).manage?
  end

  # The scene this summary belongs to, resolved to a URL via the game and
  # url_helpers supplied at construction (options[:game] / options[:urls]).
  sig { returns(String) }
  def scene_path
    @options.fetch(:urls).game_scene_path(@options.fetch(:game), @model.scene)
  end

  sig { returns(String) }
  def edit_path
    @options.fetch(:urls).edit_game_scene_scene_summary_path(@options.fetch(:game), @model.scene)
  end

  # The summary's own resource path — used both to submit the create/update
  # form and to issue the delete request, since both share one route.
  sig { returns(String) }
  def submit_path
    @options.fetch(:urls).game_scene_scene_summary_path(@options.fetch(:game), @model.scene)
  end

  sig { returns(T.untyped) }
  # mutant:disable
  def body
    @model.body
  end

  # The scene's absolute URL — RSS items link out from a feed with no
  # request context of their own, so this is the one caller needing `_url`
  # rather than `scene_path`'s in-app relative form. Same game/urls
  # collaborators, different route helper.
  sig { returns(String) }
  def scene_url
    @options.fetch(:urls).game_scene_url(@options.fetch(:game), @model.scene)
  end

  # The scene's resolved-at timestamp in RFC 2822 form, for an RSS item's
  # <pubDate> — nil when the scene (unusually, for a public summary) has no
  # resolved_at.
  sig { returns(T.nilable(String)) }
  # mutant:disable
  def scene_resolved_at_rfc2822
    resolved = @model.scene.resolved_at
    return nil unless resolved

    resolved.rfc2822
  end
end
