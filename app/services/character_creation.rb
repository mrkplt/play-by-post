# typed: strict
# frozen_string_literal: true

# Resolves the new character's owner and saves it. A GM creating on another
# player's behalf must pick a player from the roster
# (CharactersController#create's `character[user_id]` field); anyone else's
# character is always their own. Adds a validation error and reports failure
# when a GM omitted the required selection, so the controller's error-path
# render (re-showing the form) covers both failure modes uniformly.
class CharacterCreation
  extend T::Sig

  sig { params(character: Character, character_policy: CharacterPolicy, params: ActionController::Parameters).void }
  def initialize(character, character_policy, params)
    @character = character
    @character_policy = character_policy
    @params = params
  end

  sig { params(current_user: User).returns(T::Boolean) }
  def call(current_user)
    owner = resolve_owner(current_user)
    return false if owner.nil?

    @character.assign_attributes(@params.require(:character).permit(*@character_policy.permitted_attributes))
    @character.user = owner
    @character.save
  end

  private

  sig { params(current_user: User).returns(T.nilable(User)) }
  def resolve_owner(current_user)
    return current_user unless @character_policy.assign_owner?

    user_id = @params.dig(:character, :user_id)
    if user_id.blank?
      @character.errors.add(:base, "Please select a player")
      return nil
    end

    User.find(user_id)
  end
end
