# typed: strict

# The New Character / Edit Character form, built on the mobile-first component
# system. Both entry points share a name field and a markdown sheet editor
# (formatting toolbar + live preview). The GM sees a player selector when
# creating on someone's behalf; the edit form additionally offers a visibility
# toggle and an archive/restore action.
#
# The component derives its rendering mode (new vs edit), labels, and back-href
# from the presenter it is handed, so the view renders it with just the
# presenter — no form-construction logic in the template. The assign-owner
# capability lives on CharacterPresenter; the player-selector options are a
# fact about the game's roster rather than any one character, so they are
# built by CharacterPresenterBuilder and passed in directly — this component
# never receives a raw model or a raw array of users either way.
class Shared::CharacterFormComponent < ApplicationComponent
  extend T::Sig
  include Shared::RecordBackedForm

  sig { params(character: CharacterPresenter, owner_options: T::Array[[ String, Integer ]]).void }
  def initialize(character:, owner_options: [])
    @character = T.let(character, CharacterPresenter)
    @owner_options = T.let(owner_options, T::Array[[ String, Integer ]])
  end

  sig { returns(Game) }
  def game
    character.game
  end

  sig { returns(CharacterPresenter) }
  attr_reader :character

  sig { override.returns(CharacterPresenter) }
  def record
    character
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
  attr_reader :owner_options

  sig { returns(String) }
  def content_label
    mode_value(new: "Sheet (optional, markdown supported)", edit: "Sheet (markdown supported)")
  end

  sig { returns(String) }
  def submit_label
    mode_value(new: "Create Character", edit: "Save")
  end

  sig { returns(String) }
  def back_href
    mode_value(new: -> { helpers.game_path(game) }, edit: -> { helpers.game_character_path(game, character) }).call
  end

  sig { returns(String) }
  def form_id
    mode_value(new: "new_character_form", edit: "edit_character_#{character.id}_form")
  end

  private

  # The single new_record?-keyed branch every mode-dependent value goes
  # through, so the form's new/edit distinction is tested once per call
  # rather than re-testing new_record? in each label/href/id method.
  sig { type_parameters(:T).params(new: T.type_parameter(:T), edit: T.type_parameter(:T)).returns(T.type_parameter(:T)) }
  def mode_value(new:, edit:)
    new_record? ? new : edit
  end
end
