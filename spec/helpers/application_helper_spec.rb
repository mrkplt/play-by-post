require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#render_markdown" do
    it "returns empty string for blank input" do
      expect(helper.render_markdown(nil)).to eq("")
      expect(helper.render_markdown("")).to eq("")
    end

    it "renders bold text" do
      result = helper.render_markdown("**bold**")
      expect(result).to include("<strong>bold</strong>")
    end

    it "renders italic text" do
      result = helper.render_markdown("*italic*")
      expect(result).to include("<em>italic</em>")
    end

    it "renders hard line breaks" do
      result = helper.render_markdown("line one\nline two")
      expect(result).to include("<br>")
    end

    it "renders links" do
      result = helper.render_markdown("[click](http://example.com)")
      expect(result).to include('href="http://example.com"')
    end

    it "auto-links URLs" do
      result = helper.render_markdown("visit http://example.com today")
      expect(result).to include('href="http://example.com"')
    end

    it "renders strikethrough" do
      result = helper.render_markdown("~~removed~~")
      expect(result).to include("<del>removed</del>")
    end

    it "filters raw HTML" do
      result = helper.render_markdown('<script>alert("xss")</script>')
      expect(result).not_to include("<script>")
    end

    it "renders paragraphs" do
      result = helper.render_markdown("paragraph one\n\nparagraph two")
      expect(result).to include("<p>paragraph one")
      expect(result).to include("<p>paragraph two")
    end
  end
end
