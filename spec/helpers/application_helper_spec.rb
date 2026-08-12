require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#icon" do
    # Stub the gem so the substitution is asserted against a known SVG string.
    # This lets us pin the regex precisely (existing class replaced, exactly one
    # class attribute) without depending on the gem's internal default markup.
    def stub_svg(svg)
      allow(Icons::Icon).to receive(:new)
        .and_return(instance_double(Icons::Icon, svg: svg))
    end

    it "returns an SVG element" do
      result = helper.icon("crown-03")
      expect(result).to include("<svg")
      expect(result).to include("</svg>")
    end

    it "replaces an existing class attribute with the provided class" do
      stub_svg('<svg class="size-6"></svg>')
      result = helper.icon("crown-03", class: "w-4 h-4")
      # The provided class is present and the gem's original class is gone —
      # kills the branch-guard, empty-substitution and no-op (`svg = svg`) mutants.
      expect(result).to eq('<svg class="w-4 h-4"></svg>')
    end

    it "replaces a class attribute even when the existing value is empty" do
      # Kills `[^"]*` -> `[^"]+`/`[^"]`: those quantifiers cannot match an empty
      # class value, so the substitution would silently fail.
      stub_svg('<svg class=""></svg>')
      result = helper.icon("crown-03", class: "w-4 h-4")
      expect(result).to eq('<svg class="w-4 h-4"></svg>')
    end

    it "substitutes at the class attribute, not the start of the string" do
      # Kills `sub(//, ...)` and `sub(/nomatch\A/, ...)`: an empty/anchored
      # pattern would prepend the replacement rather than swap the class.
      stub_svg('<svg width="24" class="size-6"></svg>')
      result = helper.icon("crown-03", class: "w-4")
      expect(result).to eq('<svg width="24" class="w-4"></svg>')
    end

    it "does not modify the SVG when class is not provided" do
      # Kills `.present?` -> truthy and `if nil`/`if false`: with no class the
      # gem's own class must survive untouched (exactly one class attribute).
      stub_svg('<svg class="size-6"></svg>')
      result = helper.icon("crown-03")
      expect(result).to eq('<svg class="size-6"></svg>')
    end

    it "does not modify the SVG when class is blank" do
      # Kills `.present?` -> plain truthiness and `html_options[:class]` variants:
      # a blank string is truthy but not present, so no substitution runs.
      stub_svg('<svg class="size-6"></svg>')
      result = helper.icon("crown-03", class: "")
      expect(result).to eq('<svg class="size-6"></svg>')
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

    # Guards the real vendored SVG assets (not a stub) so a future re-sync that
    # re-bakes fills fails here rather than in the UI. The settings gear is a
    # single filled path with the center circle punched out as a hole via
    # fill-rule="evenodd" (filled gear, hollow center); the crown is filled; the
    # cancel X is an unfilled stroke.
    describe "vendored SVG asset fills" do
      it "renders the settings gear filled with a hollow center (evenodd hole)" do
        result = helper.icon("settings-01")
        expect(result).to include('fill="currentColor"')
        expect(result).to include('fill-rule="evenodd"')
        # A single path (both subpaths merged) so the evenodd hole applies.
        expect(result.scan("<path").size).to eq(1)
      end

      it "keeps the crown filled" do
        result = helper.icon("crown-03")
        expect(result).to include('fill="currentColor"')
      end

      it "renders the cancel X without a path fill" do
        result = helper.icon("cancel-01")
        expect(result.scan(/fill="[^"]*"/).uniq).to eq([ 'fill="none"' ])
      end
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
