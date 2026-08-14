# typed: strict

# View model for a single game link, on the New/Edit Link forms. The link's
# own manage capability and the game-nav "can manage" flag are asked of
# policies supplied at construction (options[:policy] / options[:game_policy])
# rather than looked up in the view.
class GameLinkPresenter < BasePresenter
  extend T::Sig

  sig { returns(T::Boolean) }
  def can_manage?
    @options.fetch(:policy).manage?
  end

  # The viewer may administer the game this link belongs to — the flag
  # behind the game-nav's GM-only affordances on the New/Edit Link screens.
  sig { returns(T::Boolean) }
  def can_manage_game?
    @options.fetch(:game_policy).manage?
  end

  sig { returns(T::Boolean) }
  def new_record? = @model.new_record?

  sig { returns(T.nilable(Integer)) }
  def id = @model.id

  sig { returns(T.nilable(String)) }
  def description = @model.description

  sig { returns(T::Boolean) }
  def errors? = @model.errors.any?

  sig { returns(T::Array[String]) }
  def error_messages
    @model.errors.full_messages
  end

  # The Rails model instance this presenter wraps — for `form_with model:`
  # and route helpers, which need the real ActiveRecord object.
  sig { returns(GameLink) }
  def to_model
    @model
  end
end
