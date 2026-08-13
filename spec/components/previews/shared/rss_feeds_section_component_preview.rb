# @label RSS Feeds Section
class Shared::RssFeedsSectionComponentPreview < ViewComponent::Preview
  # @label Mixed (one with a token, one without)
  def default
    game_a = Game.new(id: 1, name: "Nightfall Over Ambervale")
    game_b = Game.new(id: 2, name: "The Salt Road")
    membership_a = GameMember.new(game: game_a)
    membership_b = GameMember.new(game: game_b)
    token = ApiToken.new(id: 99, game_id: 1, token: "preview0token0value", scope: "rss")

    render(Shared::RssFeedsSectionComponent.new(
             memberships: [ membership_a, membership_b ],
             tokens_by_game_id: { 1 => token }
           ))
  end
end
