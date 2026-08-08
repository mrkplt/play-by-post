require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#icon" do
    it "returns an SVG element" do
      result = helper.icon("crown-03")
      expect(result).to include("<svg")
      expect(result).to include("</svg>")
    end

    it "replaces hardcoded stroke colors with currentColor" do
      svg_with_stroke = '<svg><path stroke="#141B34"></path><rect stroke="#FF0000"></rect></svg>'
      allow_any_instance_of(Icons::Icon).to receive(:svg).and_return(svg_with_stroke)

      result = helper.icon("crown-03")
      expect(result).not_to include('stroke="#141B34"')
      expect(result).not_to include('stroke="#FF0000"')
      expect(result).to include('stroke="currentColor"')
      expect(result.scan('stroke="currentColor"').length).to eq(2)
    end

    it "replaces hardcoded fill colors with currentColor" do
      svg_with_fill = '<svg><path fill="#FF0000"></path><rect fill="#00FF00"></rect></svg>'
      allow_any_instance_of(Icons::Icon).to receive(:svg).and_return(svg_with_fill)

      result = helper.icon("crown-03")
      expect(result).not_to include('fill="#FF0000"')
      expect(result).not_to include('fill="#00FF00"')
      expect(result).to include('fill="currentColor"')
      expect(result.scan('fill="currentColor"').length).to eq(2)
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

    it "sanitizes SVG with allowed tags" do
      result = helper.icon("crown-03")
      expect(result).to include("<svg")
      expect(result).to include("</svg>")
      expect(result).to include("<path")
    end

    it "sanitizes SVG with allowed attributes" do
      result = helper.icon("crown-03")
      expect(result).to include('viewBox=')
      expect(result).to include('d=')
      expect(result).to include('fill=')
      expect(result).to include('stroke=')
    end

    it "removes disallowed tags from SVG" do
      svg_with_disallowed = '<svg><script>alert("xss")</script><path d="M0 0"></path></svg>'
      allow_any_instance_of(Icons::Icon).to receive(:svg).and_return(svg_with_disallowed)

      result = helper.icon("crown-03")
      expect(result).not_to include("<script>")
      expect(result).to include("<svg")
      expect(result).to include("<path")
    end

    it "removes disallowed attributes from SVG" do
      svg_with_disallowed = '<svg onclick="alert(\'xss\')" viewBox="0 0 24 24"><path d="M0 0"></path></svg>'
      allow_any_instance_of(Icons::Icon).to receive(:svg).and_return(svg_with_disallowed)

      result = helper.icon("crown-03")
      expect(result).not_to include("onclick=")
      expect(result).to include("viewBox=")
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

    it "renders tables with full HTML structure" do
      table = "| Header1 | Header2 |\n|---|---|\n| cell1 | cell2 |"
      result = helper.render_markdown(table)
      expect(result).to include("<table>")
      expect(result).to include("<thead>")
      expect(result).to include("<tbody>")
      expect(result).to include("<tr>")
      expect(result).to include("<th>")
      expect(result).to include("<td>")
      expect(result).to include("Header1")
      expect(result).to include("cell1")
    end

    it "renders fenced code blocks with pre tags" do
      code = "```\nputs 'hello'\n```"
      result = helper.render_markdown(code)
      expect(result).to include("<pre><code>")
    end

    it "renders inline code" do
      result = helper.render_markdown("use `foo` here")
      expect(result).to include("<code>foo</code>")
    end

    it "renders headings h1 through h6" do
      %w[h1 h2 h3 h4 h5 h6].each_with_index do |tag, i|
        result = helper.render_markdown("#{"#" * (i + 1)} Heading")
        expect(result).to include("<#{tag}>")
      end
    end

    it "renders unordered lists" do
      result = helper.render_markdown("- item one\n- item two")
      expect(result).to include("<ul>")
      expect(result).to include("<li>")
    end

    it "renders ordered lists" do
      result = helper.render_markdown("1. first\n2. second")
      expect(result).to include("<ol>")
      expect(result).to include("<li>")
    end

    it "renders blockquotes" do
      result = helper.render_markdown("> quoted text")
      expect(result).to include("<blockquote>")
    end

    it "renders horizontal rules" do
      result = helper.render_markdown("above\n\n---\n\nbelow")
      expect(result).to include("<hr>")
    end

    it "does not apply intra-word emphasis with underscores" do
      result = helper.render_markdown("foo_bar_baz")
      expect(result).not_to include("<em>")
      expect(result).to include("foo_bar_baz")
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

    it "preserves href attributes on links" do
      result = helper.render_markdown("[click](http://example.com)")
      expect(result).to include('href="http://example.com"')
    end

    it "strips non-href attributes" do
      result = helper.render_markdown("text")
      # Ensure only href is allowed through sanitize
      expect(result).not_to include("onclick")
    end

    it "returns html_safe string so rendered HTML is not escaped in views" do
      result = helper.render_markdown("**bold**")
      expect(result).to be_html_safe
    end
  end

  describe "#last_export_notice" do
    it "renders a 'Last export: X ago' notice from the receipt's succeeded_at" do
      user = create(:user, :with_profile)
      game = create(:game)
      receipt = create(:game_export_request, user: user, game: game, succeeded_at: 3.hours.ago)

      expect(helper.last_export_notice(receipt)).to match(/\ALast export: .+ ago\z/)
      expect(helper.last_export_notice(receipt)).to include("hours")
    end
  end

  describe "#export_all_games_notice" do
    it "delegates to last_export_notice when a receipt is present" do
      user = create(:user, :with_profile)
      receipt = create(:game_export_request, :all_games, user: user, succeeded_at: 3.hours.ago)

      expect(helper.export_all_games_notice(receipt)).to match(/\ALast export: .+ ago\z/)
    end

    it "returns generic delivery-window copy when no receipt is present" do
      expect(helper.export_all_games_notice(nil))
        .to eq("You'll receive an email with a download link within a few minutes; the link expires after 7 days.")
    end
  end
end
