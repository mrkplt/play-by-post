# typed: false

require "rails_helper"

RSpec.describe Shared::RssTokenComponent, type: :component do
  context "when no token exists" do
    it "shows generate button" do
      render_inline(described_class.new(rss_token: nil))
      expect(page).to have_button("Generate RSS Token")
      expect(page).not_to have_button("Rotate Token")
      expect(page).not_to have_button("Revoke Token")
    end
  end

  context "when a token exists" do
    let(:rss_token) { build(:rss_token) }

    it "displays the token value" do
      render_inline(described_class.new(rss_token: rss_token))
      expect(page).to have_text(rss_token.token)
    end

    it "shows rotate and revoke buttons" do
      render_inline(described_class.new(rss_token: rss_token))
      expect(page).to have_button("Rotate Token")
      expect(page).to have_button("Revoke Token")
      expect(page).not_to have_button("Generate RSS Token")
    end
  end
end
