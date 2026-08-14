# typed: strict

# View model for a character sheet screen. The game-nav "can manage" flag and
# the sheet's own edit/assign-owner capabilities are asked of policies
# supplied at construction (options[:game_policy] / options[:character_policy])
# rather than looked up in the view, so a capability rename is chased through
# one construction point instead of every character template.
class CharacterPresenter < BasePresenter
  extend T::Sig

  sig { params(model: Character, options: T.untyped).void }
  def initialize(model, **options)
    super
  end

  sig { returns(String) }
  def name
    @model.name
  end

  sig { returns(String) }
  def checkbox_value
    @model.id.to_s
  end

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
end
