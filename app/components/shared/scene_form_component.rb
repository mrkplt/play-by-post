# typed: strict

# The New Scene / Quick Scene form, redesigned to match the mobile-first
# component system. A "quick" scene inherits participants and parent from the
# scene it was launched from, so it collapses to just a title field with the
# inherited context carried in hidden fields; the full form additionally offers
# participant selection, a parent scene, a private flag, and a banner image.
class Shared::SceneFormComponent < ApplicationComponent
  extend T::Sig

  PlayerRow = T.type_alias { [ UserPresenter, T::Array[Character] ] }

  sig do
    params(
      game: GamePresenter,
      scene: ScenePresenter,
      players_with_characters: T::Array[PlayerRow],
      parent_options: T::Array[[ String, Integer ]],
      quick: T::Boolean,
      selected_character_ids: T::Array[String],
      selected_parent_scene_id: T.nilable(String),
      back_href: String
    ).void
  end
  # mutant:disable
  def initialize(
    game:, scene:, players_with_characters:, parent_options:, quick:,
    selected_character_ids:, selected_parent_scene_id:, back_href:
  )
    @game = T.let(game, GamePresenter)
    @scene = T.let(scene, ScenePresenter)
    @players_with_characters = T.let(players_with_characters, T::Array[PlayerRow])
    @parent_options = T.let(parent_options, T::Array[[ String, Integer ]])
    @quick = T.let(quick, T::Boolean)
    @selected_character_ids = T.let(selected_character_ids, T::Array[String])
    @selected_parent_scene_id = T.let(selected_parent_scene_id, T.nilable(String))
    @back_href = T.let(back_href, String)
  end

  sig { returns(GamePresenter) }
  attr_reader :game

  sig { returns(ScenePresenter) }
  attr_reader :scene

  sig { returns(T::Array[PlayerRow]) }
  attr_reader :players_with_characters

  sig { returns(T::Array[[ String, Integer ]]) }
  attr_reader :parent_options

  sig { returns(T::Array[String]) }
  attr_reader :selected_character_ids

  sig { returns(T.nilable(String)) }
  attr_reader :selected_parent_scene_id

  sig { returns(String) }
  attr_reader :back_href

  sig { returns(T::Boolean) }
  def quick?
    @quick
  end

  sig { returns(String) }
  def heading
    @quick ? "Quick Scene" : "New Scene"
  end

  sig { returns(String) }
  def submit_label
    @quick ? "Create Quick Scene" : "Create Scene"
  end

  sig { returns(String) }
  def form_id
    @quick ? "quick_scene_form" : "new_scene_form"
  end

  sig { returns(String) }
  def cancel_href
    @back_href
  end

  sig { returns(T::Boolean) }
  def errors?
    @scene.errors?
  end

  sig { returns(T::Array[String]) }
  def error_messages
    @scene.error_messages
  end

  # The parent scene carried into a quick scene, so it can round-trip through a
  # hidden field without any output-tag logic in the template.
  sig { returns(String) }
  def carried_parent_scene_id
    @selected_parent_scene_id.to_s
  end
end
