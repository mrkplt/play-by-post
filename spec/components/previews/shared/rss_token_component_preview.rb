# @label RSS Token Row
class Shared::RssTokenComponentPreview < ViewComponent::Preview
  # @display bg_color "#ffffff"
  def with_token
    render(Shared::RssTokenComponent.new(
      scope_label: "Waterdeep Nights",
      feed_url: "https://example.com/feeds?token=abc123",
      form_path: "/profile/generate_rss_token",
      revoke_path: "/profile/revoke_rss_token"
    ))
  end

  def without_token
    render(Shared::RssTokenComponent.new(
      scope_label: "Curse of Strahd",
      feed_url: nil,
      form_path: "/profile/generate_rss_token",
      revoke_path: "/profile/revoke_rss_token",
      scope_param: { game_id: 42 },
      last: true
    ))
  end
end
