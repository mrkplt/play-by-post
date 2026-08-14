# typed: strict

# View model for one row of the player roster: a GameMember paired with the
# member's display name and first active character name — both joins the
# Player Management screen used to compute from raw hashes keyed by user id.
class GameMemberPresenter < BasePresenter
  extend T::Sig

  sig { params(model: GameMember, options: T.untyped).void }
  def initialize(model, **options)
    super
  end

  sig { returns(String) }
  def display_name
    UserPresenter.new(@model.user).display_name_or_email
  end

  sig { returns(T.nilable(String)) }
  def character_name
    @options.fetch(:character_name, nil)
  end

  sig { returns(T::Boolean) }
  # mutant:disable
  def active?
    @model.active?
  end

  sig { returns(T::Boolean) }
  # mutant:disable
  def removed?
    @model.removed?
  end
end
