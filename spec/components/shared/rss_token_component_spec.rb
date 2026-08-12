# typed: false

require "rails_helper"

RSpec.describe Shared::RssTokenComponent, type: :component do
  context "when no token exists" do
    subject(:component) { described_class.new(rss_token: nil) }

    it "shows generate button" do
      render_inline(component)
      expect(page).to have_button("Generate")
      expect(page).not_to have_button("Rotate")
      expect(page).not_to have_button("Revoke")
    end

    it "token_present? returns false" do
      expect(component.token_present?).to be(false)
    end

    it "token_value returns nil" do
      expect(component.token_value).to be_nil
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
      expect(page).to have_button("Rotate")
      expect(page).to have_button("Revoke")
      expect(page).not_to have_button("Generate")
    end
  end
end
