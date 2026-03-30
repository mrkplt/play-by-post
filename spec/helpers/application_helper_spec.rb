require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#icon" do
    it "returns an SVG element" do
      result = helper.icon("crown-03")
      expect(result).to include("<svg")
      expect(result).to include("</svg>")
    end

    it "replaces hardcoded stroke colors with currentColor" do
      result = helper.icon("crown-03")
      expect(result).not_to include('stroke="#141B34"')
      expect(result).to include('stroke="currentColor"')
    end

    it "replaces hardcoded fill colors with currentColor" do
      svg_with_fill = '<svg><path fill="#FF0000"></path></svg>'
      allow_any_instance_of(Icons::Icon).to receive(:svg).and_return(svg_with_fill)

      result = helper.icon("crown-03")
      expect(result).not_to include('fill="#FF0000"')
      expect(result).to include('fill="currentColor"')
    end

    it "preserves fill='none'" do
      result = helper.icon("crown-03")
      expect(result).to include('fill="none"')
    end

    it "adds a class attribute to the SVG when class is provided" do
      result = helper.icon("crown-03", class: "w-4 h-4")
      expect(result).to include('class="w-4 h-4"')
    end

    it "does not add a class attribute when class is not provided" do
      result = helper.icon("crown-03")
      # The gem adds its own class="size-6", but we should not add a duplicate
      expect(result.scan('class="').length).to eq(1)
    end

    it "passes additional HTML options as arguments to the icon" do
      icon_double = instance_double(Icons::Icon, svg: "<svg></svg>")
      expect(Icons::Icon).to receive(:new).with(
        name: "crown-03",
        library: :hugeicons,
        arguments: { class: "w-4", style: "color: red" }
      ).and_return(icon_double)

      helper.icon("crown-03", class: "w-4", style: "color: red")
    end

    it "uses the default library from configuration" do
      icon_double = instance_double(Icons::Icon, svg: "<svg></svg>")
      expect(Icons::Icon).to receive(:new).with(
        hash_including(library: :hugeicons)
      ).and_return(icon_double)

      helper.icon("crown-03")
    end

    it "allows overriding the library" do
      icon_double = instance_double(Icons::Icon, svg: "<svg></svg>")
      expect(Icons::Icon).to receive(:new).with(
        hash_including(library: "heroicons")
      ).and_return(icon_double)

      helper.icon("check", library: "heroicons")
    end

    it "returns an html_safe string" do
      result = helper.icon("crown-03")
      expect(result).to be_html_safe
    end
  end

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

    it "renders tables" do
      table = "| Header1 | Header2 |\n|---|---|\n| cell1 | cell2 |"
      result = helper.render_markdown(table)
      # sanitize strips table tags but content is still parsed from table markdown
      expect(result).to include("cell1")
      expect(result).to include("cell2")
      expect(result).not_to include("|")
    end

    it "renders fenced code blocks with pre tags" do
      code = "```\nputs 'hello'\n```"
      result = helper.render_markdown(code)
      expect(result).to include("<pre><code>")
    end

    it "does not render images" do
      result = helper.render_markdown("![alt](http://example.com/image.png)")
      expect(result).not_to include("<img")
    end

    it "strips raw HTML tags and attributes from input" do
      result = helper.render_markdown('<div class="evil">test</div>')
      expect(result).not_to include("class=")
      expect(result).not_to include("<div")
    end

    it "sanitizes dangerous HTML even if filter_html were bypassed" do
      result = helper.render_markdown('<script>alert("xss")</script>')
      expect(result).not_to include("<script>")
    end
  end
end
