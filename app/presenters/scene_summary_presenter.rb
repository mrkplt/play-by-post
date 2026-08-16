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
    return "Hand-written" unless @model.ai_generated?

    @model.edited? ? "Edited" : "AI-generated"
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
