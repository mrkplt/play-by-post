# typed: strict

# View model for a character sheet screen. The game-nav "can manage" flag and
# the sheet's own edit/assign-owner capabilities are asked of policies
# supplied at construction (options[:game_policy] / options[:character_policy])
# rather than looked up in the view, so a capability rename is chased through
# one construction point instead of every character template.
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

  sig { returns(String) }
  def name
    @model.name
  end

  sig { returns(T::Boolean) }
  def archived? = @model.archived?

  sig { returns(T::Boolean) }
  def hidden? = @model.hidden?

  sig { returns(T::Boolean) }
  def content? = @model.content.present?

  sig { returns(String) }
  def content
    @model.content.to_s
  end

  sig { returns(T::Boolean) }
  def new_record? = @model.new_record?

  sig { returns(T.nilable(Integer)) }
  def id = @model.id

  sig { returns(T::Boolean) }
  def errors? = @model.errors.any?

  sig { returns(T::Array[String]) }
  def error_messages
    @model.errors.full_messages
  end

  # The Rails model instance this presenter wraps — for `form_with model:`
  # and route helpers, which need the real ActiveRecord object (persisted?,
  # to_key, route params), not a re-derived display value.
  sig { returns(Character) }
  def to_model
    @model
  end
end
