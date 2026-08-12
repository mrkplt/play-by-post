# User-input sanitization — the XSS invariant (Fizzy #16)

## The concern

Markdown intrinsically allows a fallback to arbitrary inline HTML, which could
embed JavaScript. That must never reach a rendered page.

## Current state (audited — the app is safe)

The pipeline is already closed, and is now pinned by tests:

- **`MarkdownRenderer`** (`app/services/markdown_renderer.rb`) is the single path
  from user prose to HTML. It defends in two layers:
  1. Redcarpet renderer with `filter_html: true` (strips raw HTML tags), and
  2. Rails `sanitize` with an explicit **tag allowlist** (`ALLOWED_TAGS`) and an
     **href-only attribute allowlist** (`ALLOWED_ATTRIBUTES`). `sanitize` also
     drops unsafe URI schemes, so `javascript:` / `vbscript:` / `data:` hrefs are
     removed while the link text survives.
  - Verified against `<script>`, `onerror`/`onclick` handlers, `javascript:`/
    `vbscript:`/`data:` hrefs, and `<iframe>` — every vector is neutralized. See
    `spec/services/markdown_renderer_spec.rb`.

- **Plain-text fields** (page/scene/game titles, display names) render through
  ERB `<%= %>`, which auto-escapes HTML entities. No raw interpolation of user
  text.

- **The only `raw`/`html_safe`/`<%==` sites in the app carry no user input:**
  - `scene_summary_index_page_component.html.erb` — `<%== @pagy.series_nav %>`
    (Pagy-generated pagination markup).
  - `application_helper.rb` — `svg.html_safe` (icon SVGs from the `icons` gem).

## The invariant to keep

- **All user prose renders through `MarkdownRenderer`.** There is no
  "plain textarea for prose" — every multi-line prose field is a markdown field
  (see CLAUDE.md "Forms & text fields").
- **Never `raw` / `html_safe` / `<%==` user input.** If a new render path needs
  HTML from user text, route it through `MarkdownRenderer`, and add it to the
  vector spec above.
