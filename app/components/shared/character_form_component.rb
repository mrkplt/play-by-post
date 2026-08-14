# typed: strict

# The New Character / Edit Character form, built on the mobile-first component
# system. Both entry points share a name field and a markdown sheet editor
# (formatting toolbar + live preview). The GM sees a player selector when
# creating on someone's behalf; the edit form additionally offers a visibility
# toggle and an archive/restore action.
#
# The component derives its rendering mode (new vs edit), labels, and back-href
# from the presenter it is handed, so the view renders it with just the
# presenter — no form-construction logic in the template. The player-selector
# options and the assign-owner capability both live on CharacterPresenter, so
# this component never receives a raw model or a raw array of users.
class Shared::CharacterFormComponent < ApplicationComponent
  extend T::Sig

  sig { params(character: CharacterPresenter).void }
  def initialize(character:)
    @character = T.let(character, CharacterPresenter)
  end

  sig { returns(Game) }
  def game
    character.game
  end

  sig { returns(CharacterPresenter) }
  attr_reader :character

  sig { returns(T::Boolean) }
  def new_record?
    character.new_record?
  end

  sig { returns(T::Boolean) }
  def archived?
    character.archived?
  end

  # The GM's player selector only makes sense when creating a new character on
  # someone's behalf; once created, ownership is fixed.
  sig { returns(T::Boolean) }
  def owner_select?
    new_record? && character.can_assign_owner?
  end

  sig { returns(T::Boolean) }
  def visibility_toggle?
    !new_record?
  end

  # Archive/restore is a GM affordance on an existing character.
  sig { returns(T::Boolean) }
  def archive_section?
    !new_record? && character.can_assign_owner?
  end

  sig { returns(T::Array[[ String, Integer ]]) }
  def owner_options
    character.owner_options
  end

  sig { returns(String) }
  def content_label
    new_record? ? "Sheet (optional, markdown supported)" : "Sheet (markdown supported)"
  end

  sig { returns(String) }
  def submit_label
    new_record? ? "Create Character" : "Save"
  end

  sig { returns(String) }
  def back_href
    new_record? ? helpers.game_path(game) : helpers.game_character_path(game, character)
  end

  sig { returns(String) }
  def form_id
    new_record? ? "new_character_form" : "edit_character_#{character.id}_form"
  end

  sig { returns(T::Boolean) }
  def errors?
    character.errors?
  end

  sig { returns(T::Array[String]) }
  def error_messages
    character.error_messages
  end
end
