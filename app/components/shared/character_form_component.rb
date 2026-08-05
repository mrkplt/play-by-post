# typed: strict

# The New Character / Edit Character form, built on the mobile-first component
# system. Both entry points share a name field and a markdown sheet editor
# (formatting toolbar + live preview). The GM sees a player selector when
# creating on someone's behalf; the edit form additionally offers a
# visibility toggle and an archive/restore action. Rendering mode is driven by
# explicit presentation flags rather than by inspecting the record, so the
# template stays free of domain branching.
class Shared::CharacterFormComponent < ApplicationComponent
  extend T::Sig

  sig do
    params(
      game: Game,
      character: Character,
      users: T::Array[User],
      new_record: T::Boolean,
      can_assign_owner: T::Boolean,
      archived: T::Boolean,
      back_href: String
    ).void
  end
  def initialize(game:, character:, users:, new_record:, can_assign_owner:, archived:, back_href:)
    @game = T.let(game, Game)
    @character = T.let(character, Character)
    @users = T.let(users, T::Array[User])
    @new_record = T.let(new_record, T::Boolean)
    @can_assign_owner = T.let(can_assign_owner, T::Boolean)
    @archived = T.let(archived, T::Boolean)
    @back_href = T.let(back_href, String)
  end

  sig { returns(Game) }
  attr_reader :game

  sig { returns(Character) }
  attr_reader :character

  sig { returns(String) }
  attr_reader :back_href

  sig { returns(T::Boolean) }
  def archived?
    @archived
  end

  # The GM's player selector only makes sense when creating a new character on
  # someone's behalf; once created, ownership is fixed.
  sig { returns(T::Boolean) }
  def owner_select?
    @new_record && @can_assign_owner
  end

  sig { returns(T::Boolean) }
  def visibility_toggle?
    !@new_record
  end

  # Archive/restore is a GM affordance on an existing character.
  sig { returns(T::Boolean) }
  def archive_section?
    !@new_record && @can_assign_owner
  end

  sig { returns(T::Array[[ String, Integer ]]) }
  def owner_options
    @users.map { |user| [ user.display_name || user.email, user.id ] }
  end

  sig { returns(String) }
  def content_label
    @new_record ? "Sheet (optional, markdown supported)" : "Sheet (markdown supported)"
  end

  sig { returns(String) }
  def submit_label
    @new_record ? "Create Character" : "Save"
  end

  sig { returns(T::Boolean) }
  def errors?
    @character.errors.any?
  end

  sig { returns(T::Array[String]) }
  def error_messages
    @character.errors.full_messages
  end
end
