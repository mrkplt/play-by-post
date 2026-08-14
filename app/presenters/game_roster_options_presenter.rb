# typed: strict

# The game's active players as select options — display name (falling back to
# email) paired with the user's id.
#
# A fact about the game's roster rather than about any one character, so it
# does not belong on CharacterPresenter; split out of GamePresenter (which it
# wraps — composition, not duplication) to keep that class under the project's
# method and file-length ceilings.
class GameRosterOptionsPresenter < BasePresenter
  extend T::Sig

  sig { params(model: GamePresenter, options: T.untyped).void }
  def initialize(model, **options)
    super
  end

  sig { returns(T::Array[[ String, Integer ]]) }
  def owner_options
    players_for_select.map { |user| UserPresenter.new(user).select_option }
  end

  private

  sig { returns(T::Array[User]) }
  def players_for_select
    @model.model.active_members.where(role: "player").includes(:user).map(&:user)
  end
end
