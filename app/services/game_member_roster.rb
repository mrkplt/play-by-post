# typed: strict
# frozen_string_literal: true

# The GM's member roster for a game: each non-banned player membership paired
# with that user's first active character name, as GameMemberPresenter rows.
# Shared by PlayerManagementController#show (the initial render) and
# GameMembersController#update (the in-place re-render after a status change), so
# the two cannot disagree on how the roster is built.
class GameMemberRoster
  extend T::Sig

  sig { params(game: Game).void }
  def initialize(game)
    @game = game
  end

  sig { returns(T::Array[GameMemberPresenter]) }
  def rows
    characters_by_user = Character.first_active_name_by_user(@game.characters.active)
    members = @game.game_members.where.not(status: "banned").where(role: "player").includes(:user)
    members.map { |member| GameMemberPresenter.new(member, character_name: characters_by_user[member.user_id]) }
  end
end
