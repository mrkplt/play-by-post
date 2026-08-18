# typed: strict

# View model for a scene's thread/participant navigation links: the
# "Continues from" parent link, notification toggle, GM scene-action links,
# and the Edit Participants screen's own routes. Wraps a
# ScenePresenter — composition, not duplication — per the layering rule that
# a presenter's subject may be a model or another presenter, and split out
# from ScenePresenter purely to keep each presenter under the project's
# file-length ceiling. The game and url_helpers are supplied at construction
# (options[:game] / options[:urls]) so the view never builds a route itself.
class SceneNavigationPresenter < BasePresenter
  extend T::Sig

  sig { params(model: ScenePresenter, options: T.untyped).void }
  def initialize(model, **options)
    super
  end

  # Whether this scene continues from another — the "Continues from" thread
  # link at the top of the scene screen.
  sig { returns(T::Boolean) }
  def parent_scene?
    @model.model.parent_scene.present?
  end

  sig { returns(String) }
  def parent_scene_title
    @model.model.parent_scene.title
  end

  # The parent scene's own show page — the "Continues from" link's target.
  sig { returns(String) }
  def parent_scene_path
    @options.fetch(:urls).game_scene_path(@options.fetch(:game), @model.model.parent_scene)
  end

  sig { returns(String) }
  def toggle_notification_preference_path
    @options.fetch(:urls).toggle_notification_preference_game_scene_path(@options.fetch(:game), @model.model)
  end

  # The GM scene-actions row's "Quick Scene" link — a child scene pre-flagged
  # for the abbreviated form.
  sig { returns(String) }
  def quick_child_scene_path
    @options.fetch(:urls).new_game_scene_path(@options.fetch(:game), quick: true, parent_scene_id: @model.model.id)
  end

  sig { returns(String) }
  def new_child_scene_path
    @options.fetch(:urls).new_game_scene_path(@options.fetch(:game), parent_scene_id: @model.model.id)
  end

  sig { returns(String) }
  def edit_participants_path
    @options.fetch(:urls).edit_game_scene_participants_path(@options.fetch(:game), @model.model)
  end

  # The Edit Participants form's submit target — same resource as
  # #edit_participants_path, different HTTP verb (PATCH).
  sig { returns(String) }
  def participants_path
    @options.fetch(:urls).game_scene_participants_path(@options.fetch(:game), @model.model)
  end

  # This scene's own show page — the Edit Participants screen's Cancel link.
  sig { returns(String) }
  def show_path
    @options.fetch(:urls).game_scene_path(@options.fetch(:game), @model.model)
  end
end
