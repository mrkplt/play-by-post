# @label Sidebar
class Shared::SidebarComponentPreview < ViewComponent::Preview
  def signed_out
    render(Shared::SidebarComponent.new(current_user: nil))
  end

  def signed_in
    user = User.first || User.new(email: "player@example.com")
    game = Game.first || Game.new(id: 1, name: "Sample Game")
    game_presenter = GamePresenter.new(game, policy: GamePolicy.new(user, game))
    render(Shared::SidebarComponent.new(current_user: UserPresenter.new(user), games: [ game_presenter ]))
  end
end
