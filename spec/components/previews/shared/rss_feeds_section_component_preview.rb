# @label RSS Feeds Section
class Shared::RssFeedsSectionComponentPreview < ViewComponent::Preview
  # Renders the current lookbook user's real feeds section. Create a game
  # membership (and optionally an rss ApiToken) to see both row states.
  def default
    render(Shared::RssFeedsSectionComponent.new(user: User.first || User.new))
  end
end
