# typed: strict

# The New Scene / Quick Scene form, redesigned to match the mobile-first
# component system. A "quick" scene inherits participants and parent from the
# scene it was launched from, so it collapses to just a title field with the
# inherited context carried in hidden fields; the full form additionally offers
# participant selection, a parent scene, a private flag, and a banner image.
# Everything but the two domain subjects (game, scene) travels as one
# Selection (see scene_form_component/selection.rb).
class Shared::SceneFormComponent < ApplicationComponent
  extend T::Sig

  sig { params(game: GamePresenter, scene: ScenePresenter, selection: Selection).void }
  def initialize(game:, scene:, selection:)
    @game = T.let(game, GamePresenter)
    @scene = T.let(scene, ScenePresenter)
    @selection = T.let(selection, Selection)
  end

  sig { returns(GamePresenter) }
  attr_reader :game

  sig { returns(ScenePresenter) }
  attr_reader :scene

  sig { returns(T::Array[ScenePlayerPresenter]) }
  def players_with_characters
    @selection.players_with_characters
  end

  sig { returns(T::Array[[ String, Integer ]]) }
  def parent_options
    @selection.parent_options
  end

  sig { returns(T::Array[String]) }
  def selected_character_ids
    @selection.selected_character_ids
  end

  sig { returns(T.nilable(String)) }
  def selected_parent_scene_id
    @selection.selected_parent_scene_id
  end

  sig { returns(String) }
  def back_href
    @selection.back_href
  end

  sig { returns(T::Boolean) }
  def quick?
    @selection.quick
  end

  sig { returns(String) }
  def heading
    mode_value(quick: "Quick Scene", full: "New Scene")
  end

  sig { returns(String) }
  def submit_label
    mode_value(quick: "Create Quick Scene", full: "Create Scene")
  end

  sig { returns(String) }
  def form_id
    mode_value(quick: "quick_scene_form", full: "new_scene_form")
  end

  sig { returns(String) }
  def cancel_href
    back_href
  end

  sig { returns(T::Array[String]) }
  def error_messages
    @scene.error_messages
  end

  # The parent scene carried into a quick scene, so it can round-trip through a
  # hidden field without any output-tag logic in the template.
  sig { returns(String) }
  def carried_parent_scene_id
    selected_parent_scene_id.to_s
  end

  private

  # The single @selection.quick-keyed branch heading/submit_label/form_id go
  # through, so the quick/full distinction is tested once per call rather
  # than repeating the ternary in each label method.
  sig { type_parameters(:T).params(quick: T.type_parameter(:T), full: T.type_parameter(:T)).returns(T.type_parameter(:T)) }
  def mode_value(quick:, full:)
    quick? ? quick : full
  end
end
