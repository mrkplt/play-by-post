require "rails_helper"

# MarkdownRenderer is the single sanctioned path for turning user prose into
# HTML. Its security contract: no user input may reach the page as executable
# code. These specs lock in that contract against the common XSS vectors —
# markdown "intrinsically allows fallback to arbitrary HTML," and this is where
# that fallback is closed (filter_html + a tag/attribute allowlist that also
# drops unsafe URI schemes). See context/DESIGN_TOKEN_COMPILATION.md's sibling
# invariant in CLAUDE.md: all prose renders through MarkdownRenderer; never
# `raw`/`html_safe` user input.
RSpec.describe MarkdownRenderer do
  def render(text)
    described_class.render(text)
  end

  describe "safe markdown (happy path)" do
    it "renders bold and emphasis" do
      expect(render("**bold** and _em_")).to eq("<p><strong>bold</strong> and <em>em</em></p>\n")
    end

    it "keeps a safe http(s) link with its href" do
      out = render("[site](https://example.com)")
      expect(out).to include('<a href="https://example.com">site</a>')
    end

    it "renders lists, headings, and code" do
      out = render("# Title\n\n- one\n- two\n\n`code`")
      expect(out).to include("<h1>Title</h1>")
      expect(out).to include("<li>one</li>")
      expect(out).to include("<code>code</code>")
    end

    it "returns an empty string for blank input" do
      expect(render(nil)).to eq("")
      expect(render("")).to eq("")
      expect(render("   ")).to eq("")
    end
  end

  describe "renderer options (each is load-bearing)" do
    it "hard-wraps a single newline into <br> (hard_wrap)" do
      expect(render("line one\nline two")).to include("<br>")
    end

    it "renders bare URLs as links (autolink)" do
      out = render("visit https://example.com now")
      expect(out).to include('<a href="https://example.com">https://example.com</a>')
    end

    it "renders pipe tables (tables)" do
      out = render("| a | b |\n| - | - |\n| 1 | 2 |")
      expect(out).to include("<table>")
      expect(out).to include("<td>1</td>")
    end

    it "renders ~~text~~ as struck-through (strikethrough)" do
      expect(render("~~gone~~")).to include("<del>gone</del>")
    end

    it "renders fenced code blocks (fenced_code_blocks)" do
      out = render("```\nx = 1\n```")
      expect(out).to include("<pre>")
      expect(out).to include("<code>")
      expect(out).to include("x = 1")
    end

    it "does not emphasize intra-word underscores (no_intra_emphasis)" do
      out = render("foo_bar_baz")
      expect(out).not_to include("<em>")
      expect(out).to include("foo_bar_baz")
    end

    it "keeps markdown links as anchors (no_links: false)" do
      expect(render("[site](https://example.com)")).to include("<a href=")
    end

    it "does not emit an <img> for markdown image syntax (no_images)" do
      out = render("![alt text](https://example.com/x.png)")
      expect(out).not_to include("<img")
    end
  end

  describe "XSS neutralization (security contract)" do
    it "strips <script> tags, keeping only text" do
      out = render("<script>alert(1)</script>")
      expect(out).not_to include("<script")
      expect(out).not_to include("alert(1)</script")
    end

    it "removes an <img> with an onerror handler" do
      out = render("<img src=x onerror=alert(1)>")
      expect(out).not_to include("<img")
      expect(out).not_to include("onerror")
    end

    it "strips event-handler attributes from allowed elements" do
      out = render(%(<div onclick="alert(1)">hi</div>))
      expect(out).not_to include("onclick")
      expect(out).to include("hi")
    end

    it "drops javascript: hrefs (link text survives, href does not)" do
      out = render("[click](javascript:alert(1))")
      expect(out).not_to include("javascript:")
      expect(out).to include("click")
    end

    it "drops javascript: hrefs regardless of case" do
      out = render("[click](JaVaScRiPt:alert(1))")
      expect(out.downcase).not_to include("javascript:")
    end

    it "drops vbscript: hrefs" do
      out = render("[x](vbscript:msgbox(1))")
      expect(out).not_to include("vbscript:")
    end

    it "drops data: hrefs carrying markup" do
      out = render("[data](data:text/html,<script>alert(1)</script>)")
      expect(out).not_to include("data:text/html")
      expect(out).not_to include("<script")
    end

    it "strips a raw <a> with a javascript: href, keeping only text" do
      out = render(%(<a href="javascript:alert(1)">x</a>))
      expect(out).not_to include("javascript:")
      expect(out).to include("x")
    end

    it "removes an <iframe> entirely" do
      out = render("<iframe src=evil></iframe>")
      expect(out).not_to include("<iframe")
      expect(out).not_to include("evil")
    end

    it "never emits an on* attribute or a <script>/<iframe> tag for a mixed payload" do
      out = render("normal text <script>alert(1)</script> [ok](https://ok.test) <img src=x onerror=alert(1)>")
      expect(out).not_to match(/<script|<iframe|<img|on\w+=/)
      expect(out).to include('<a href="https://ok.test">ok</a>')
    end
  end
end
