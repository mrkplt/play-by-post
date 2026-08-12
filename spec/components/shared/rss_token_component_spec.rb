# typed: false

require "rails_helper"

RSpec.describe Shared::RssTokenComponent, type: :component do
  def component(**overrides)
    described_class.new(**{
      scope_label: "All games",
      feed_url: nil,
      form_path: "/profile/generate_rss_token",
      revoke_path: "/profile/revoke_rss_token"
    }.merge(overrides))
  end

  context "when no token exists" do
    subject(:instance) { component }

    it "shows a generate button and no rotate/revoke" do
      render_inline(instance)
      expect(page).to have_button("Generate")
      expect(page).not_to have_button("Rotate")
      expect(page).not_to have_button("Revoke")
    end

    it "does not render a feed URL field" do
      render_inline(instance)
      expect(page).not_to have_text("Feed URL")
    end

    it "reports the token is absent" do
      expect(instance.token_present?).to be(false)
    end

    it "labels the action Generate" do
      expect(instance.action_label).to eq("Generate")
    end

    it "carries no rotate confirmation" do
      expect(instance.rotate_data).to eq({})
    end
  end

  context "when a token exists" do
    subject(:instance) { component(feed_url: "https://example.com/feeds?token=xyz") }

    it "shows rotate and revoke buttons" do
      render_inline(instance)
      expect(page).to have_button("Rotate")
      expect(page).to have_button("Revoke")
      expect(page).not_to have_button("Generate")
    end

    it "renders the feed URL in a secret field" do
      render_inline(instance)
      expect(page).to have_text("Feed URL")
      expect(page).to have_field(with: "https://example.com/feeds?token=xyz")
    end

    it "reports the token is present" do
      expect(instance.token_present?).to be(true)
    end

    it "labels the action Rotate" do
      expect(instance.action_label).to eq("Rotate")
    end

    it "carries a rotate confirmation" do
      expect(instance.rotate_data).to include(:confirm)
    end
  end

  describe "#scope_label" do
    it "renders the scope label" do
      render_inline(component(scope_label: "Curse of Strahd"))
      expect(page).to have_text("Curse of Strahd")
    end
  end

  describe "#feed_url" do
    it "returns the URL string when present" do
      expect(component(feed_url: "https://example.com/feeds?token=x").feed_url)
        .to eq("https://example.com/feeds?token=x")
    end

    it "returns an empty string (not nil) when absent" do
      expect(component(feed_url: nil).feed_url).to eq("")
    end
  end

  describe "#rotate_data" do
    it "is empty without a token" do
      expect(component(feed_url: nil).rotate_data).to eq({})
    end

    it "carries only a confirm key with a token" do
      data = component(feed_url: "https://example.com/feeds?token=x").rotate_data
      expect(data.keys).to eq([ :confirm ])
    end
  end

  describe "#divide? / last" do
    it "divides by default (last omitted)" do
      expect(component.divide?).to be(true)
    end

    it "does not divide when marked last" do
      expect(component(last: true).divide?).to be(false)
    end
  end
end
