# typed: strict

# The GM's "Invite a Player" controls on the game Roster tab: an email invite
# form plus the list of pending invitations (each one cancellable). GM-only —
# the caller gates rendering on the GM check.
class Shared::InvitePanelComponent < ApplicationComponent
  extend T::Sig

  sig { params(game: Game, pending_invitations: T::Array[Invitation]).void }
  # mutant:disable
  def initialize(game:, pending_invitations:)
    @game = T.let(game, Game)
    @pending_invitations = T.let(pending_invitations, T::Array[Invitation])
  end

  sig { returns(T::Array[Invitation]) }
  attr_reader :pending_invitations

  sig { returns(T::Boolean) }
  def pending?
    @pending_invitations.any?
  end

  sig { returns(String) }
  def invite_url
    helpers.game_player_management_invitations_path(@game)
  end

  sig { params(invitation: Invitation).returns(String) }
  def cancel_url(invitation)
    helpers.game_player_management_invitation_path(@game, invitation)
  end

  sig { params(invitation: Invitation).returns(String) }
  def resend_url(invitation)
    helpers.resend_game_player_management_invitation_path(@game, invitation)
  end

  sig { params(invitation: Invitation).returns(String) }
  def sent_label(invitation)
    "Sent #{helpers.time_ago_in_words(invitation.created_at)} ago"
  end

  sig { params(index: Integer).returns(T::Boolean) }
  def last?(index)
    index == @pending_invitations.length - 1
  end
end
