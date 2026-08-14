# typed: strict

# The GM's "Invite a Player" controls on the game Roster tab: an email invite
# form plus the list of pending invitations (each one cancellable). GM-only —
# the caller gates rendering on the GM check.
class Shared::InvitePanelComponent < ApplicationComponent
  extend T::Sig

  sig { params(game: GamePresenter, pending_invitations: T::Array[InvitationPresenter]).void }
  # mutant:disable
  def initialize(game:, pending_invitations:)
    @game = T.let(game, GamePresenter)
    @pending_invitations = T.let(pending_invitations, T::Array[InvitationPresenter])
  end

  sig { returns(T::Array[InvitationPresenter]) }
  attr_reader :pending_invitations

  sig { returns(T::Boolean) }
  def pending?
    @pending_invitations.any?
  end

  sig { returns(String) }
  def invite_url
    helpers.game_player_management_invitations_path(@game)
  end

  sig { params(index: Integer).returns(T::Boolean) }
  def last?(index)
    index == @pending_invitations.length - 1
  end
end
