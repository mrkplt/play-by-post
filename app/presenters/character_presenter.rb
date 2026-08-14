# typed: strict

# View model for a character sheet screen. The game-nav "can manage" flag and
# the sheet's own edit/assign-owner capabilities are asked of policies
# supplied at construction (options[:game_policy] / options[:character_policy])
# rather than looked up in the view, so a capability rename is chased through
# one construction point instead of every character template. Explicit sigs
# are declared for everything the character form/detail components read —
# SimpleDelegator passthrough is invisible to Sorbet, so a component may not
# call an undeclared method on this presenter even though it would resolve
# at runtime.
class CharacterPresenter < BasePresenter
  extend T::Sig

  # The viewer may administer the game this character belongs to — the flag
  # behind the game-nav's GM-only affordances on every character screen.
  sig { returns(T::Boolean) }
  def can_manage_game?
    @options.fetch(:game_policy).manage?
  end

  # The viewer may edit this character sheet.
  sig { returns(T::Boolean) }
  def can_edit?
    @options.fetch(:character_policy).update?
  end

  # Only the GM may reassign a sheet's owner — the character-form's player
  # selector and the roster archive/restore affordance both key off this.
  sig { returns(T::Boolean) }
  def can_assign_owner?
    @options.fetch(:character_policy).assign_owner?
  end

  sig { returns(Game) }
  def game
    @model.game
  end

  sig { returns(String) }
  def name
    @model.name.to_s
  end

  sig { returns(String) }
  def content
    @model.content.to_s
  end

  sig { returns(T::Boolean) }
  def content?
    @model.content.present?
  end

  sig { returns(T::Boolean) }
  def archived? = @model.archived?

  sig { returns(T::Boolean) }
  def hidden? = @model.hidden?

  sig { returns(T::Boolean) }
  def new_record? = @model.new_record?

  sig { returns(T.nilable(Integer)) }
  def id = @model.id

  sig { returns(T::Boolean) }
  def errors?
    @model.errors.any?
  end

  sig { returns(T::Array[String]) }
  def error_messages
    @model.errors.full_messages
  end

  # The character form's player selector options — display name (falling back
  # to email) paired with the user's id — built from the players supplied at
  # construction (options[:players]) rather than the component receiving raw
  # users to map itself.
  sig { returns(T::Array[[ String, Integer ]]) }
  def owner_options
    T.cast(@options.fetch(:players, []), T::Array[User]).map do |user|
      [ user.display_name || user.email, user.id ]
    end
  end
end
