require "rails_helper"

RSpec.describe Shared::MuteToggleComponent, type: :component do
  def render_toggle(muted:)
    render_inline(described_class.new(toggle_url: "/games/g/scenes/s/toggle_notification_preference", muted: muted))
  end

  it "labels the control Mute when the viewer is not muted" do
    render_toggle(muted: false)
    expect(page).to have_link("Mute notifications")
    expect(page).to have_no_link("Unmute notifications")
  end

  it "labels the control Unmute when the viewer is muted" do
    render_toggle(muted: true)
    expect(page).to have_link("Unmute notifications")
    expect(page).to have_no_link("Mute notifications")
  end

  it "renders inside the stable wrapper id and posts to the toggle url" do
    render_toggle(muted: false)
    expect(page).to have_css("##{Shared::MuteToggleComponent::DOM_ID}")
    expect(page).to have_css(
      "a[href='/games/g/scenes/s/toggle_notification_preference'][data-turbo-method='post']"
    )
  end
end
