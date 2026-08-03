# @label Invite Panel
class Shared::InvitePanelComponentPreview < ViewComponent::Preview
  def with_pending_invitations
    game = Game.first || Game.new(name: "Sample Game")
    pending = game.persisted? ? game.invitations.pending.to_a : []
    render(Shared::InvitePanelComponent.new(game: game, pending_invitations: pending))
  end

  def no_pending_invitations
    game = Game.first || Game.new(name: "Sample Game")
    render(Shared::InvitePanelComponent.new(game: game, pending_invitations: []))
  end
end
