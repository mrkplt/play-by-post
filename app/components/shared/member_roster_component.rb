# typed: strict

# The GM's "Members" roster on the Player Management screen: one settings row per
# non-banned player membership, its trailing controls (Remove/Ban, or Reinstate)
# following the member's status. Wrapped in a stable id so GameMembersController
# can re-render it in place after a status change without reloading the screen.
#
# Takes presentation-ready GameMemberPresenter rows and the owning game
# presenter (for the action URLs) — never raw models.
class Shared::MemberRosterComponent < ApplicationComponent
  extend T::Sig

  # The stable wrapper id the page renders and the in-place update targets.
  DOM_ID = "member_roster"

  sig { params(game: GamePresenter, members: T::Array[GameMemberPresenter]).void }
  def initialize(game:, members:)
    @game = game
    @members = members
  end

  sig { returns(GamePresenter) }
  attr_reader :game

  sig { returns(T::Array[GameMemberPresenter]) }
  attr_reader :members

  sig { returns(T::Boolean) }
  def any?
    members.any?
  end

  # The row's position within the card list — :last on the final row so it drops
  # its divider, :middle otherwise.
  sig { params(member: GameMemberPresenter).returns(Symbol) }
  def position(member)
    member.equal?(members.last) ? :last : :middle
  end

  sig { params(member: GameMemberPresenter, status: String).returns(String) }
  def status_url(member, status)
    helpers.game_player_management_game_member_path(game, member, status: status)
  end
end
