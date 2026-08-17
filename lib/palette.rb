# typed: true
# frozen_string_literal: true

# The single source of truth for every colour in the application.
#
# Edit colours HERE and nowhere else. Two consumers derive from this one hash:
#
#   1. CSS / Tailwind — `bin/build-palette` (run automatically before
#      `tailwindcss:build`, i.e. during `assets:precompile` and the dev puma
#      plugin) writes these into `app/assets/tailwind/_palette.css` as a
#      generated `@theme` block, so the utilities (`bg-accent`, `text-muted`, …)
#      compile exactly as before.
#   2. Ruby at runtime — mailers, presenters, and anywhere else Ruby renders a
#      colour read it directly via `Palette[:muted]`. Mail clients cannot use the
#      compiled stylesheet, so emails inline the hex; pulling it from here keeps
#      emails on the same palette as the rest of the app, without exception.
#
# `bin/check-palette-sync` fails CI if the generated CSS drifts from this file.
#
# GROUPS is an ordered list of [heading, { token => hex }] pairs. The heading
# comments are reproduced in the generated CSS so it reads like the original
# hand-written @theme block. `COLORS` is the flat token => hex map used by both
# the generator and the runtime accessor.
module Palette
  GROUPS = [
    [ "Ink & canvas", {
      "ink" => "#1a1a1a",
      "canvas" => "#fafafa",
    } ],
    [ "Dark surfaces (header bars, drawer)", {
      "sidebar-bg" => "#2b2d31",       # header bars
      "drawer-bg" => "#1a1b1e",        # nav drawer / darkest surface
      "sidebar-text" => "#cdd1d9",
      "sidebar-border" => "#3d3f45",
      "sidebar-hover" => "#3a3c42",
      "pill-idle" => "#3a3c42",        # inactive pill tab background
    } ],
    [ "Accent (gold)", {
      "accent" => "#c8a96e",
      "accent-ink" => "#1a1a1a",       # text on gold surfaces
    } ],
    [ "Light card surfaces", {
      "card" => "#ffffff",
      "card-border" => "#e8e6e1",
      "card-divider" => "#f0eee9",
      "input-border" => "#d8d5cd",     # warm border on text inputs / textareas
    } ],
    [ "Muted greys", {
      "muted" => "#8a8d94",            # labels, meta
      "muted-2" => "#9aa0ab",          # tertiary meta
      "body-ink" => "#2a2a2a",         # post body text
      "row-ink" => "#5c5e63",          # row secondary text
    } ],
    [ "Sodalite/azurite blue — retired / OOC / banned tint", {
      "tint-blue-bg" => "#e6ebf4",
      "tint-blue-border" => "#c7d2e6",
      "tint-blue-strong" => "#2a4570",
      "tint-blue-soft" => "#4d6690",
    } ],
    [ "Danger (ban / cancel / unban)", {
      "danger" => "#9c3a3a",
      "danger-soft" => "#7a3a3a",
    } ],
    [ "Avatar initials backgrounds (non-blue tones; blue reuses tint)", {
      "avatar-muted" => "#c2beb6",     # warm grey avatar
      "avatar-blue" => "#94a8c9",      # blue avatar
    } ],
    [ "Badge tones — dark chip backgrounds with tinted text/border", {
      "badge-danger-bg" => "#3a1717",
      "badge-danger-text" => "#e28a8a",
      "badge-danger-border" => "#5c2121",
      "badge-gold-bg" => "#3a3020",
      "badge-gold-text" => "#e2c48a",
      "badge-gold-border" => "#5c4a2c",
    } ],
    [ "Toast surfaces — light chips overlaid on content", {
      "toast-success-bg" => "#e7f4ec",
      "toast-success-text" => "#1f5133",
      "toast-success-border" => "#bcdcc9",
      "toast-error-bg" => "#fbeaea",
      "toast-error-text" => "#7a2626",
      "toast-error-border" => "#e6c3c3",
    } ],
    [ "OOC filter toggle indicator (Stimulus reads these via utility classes)", {
      "toggle-on" => "#16a34a",        # green "✓ On" text
      "toggle-off" => "#94a3b8",       # grey "Off" text
    } ],
    [ "Email — inline styles in mailer views (mail clients can't use Tailwind)", {
      "mail-meta" => "#64748b",        # muted meta text in emails
      "mail-action" => "#1e40af",      # primary button background in emails
      "mail-rule" => "#e2e8f0",        # divider / left border in digests
    } ],
  ].freeze

  COLORS = GROUPS.each_with_object({}) do |(_heading, tokens), acc|
    acc.merge!(tokens)
  end.freeze

  # Look up a colour by token name. Tokens are hyphenated to match the CSS
  # custom-property names (`--color-mail-meta`), but Ruby callers may use the
  # idiomatic underscore form — Palette[:mail_meta] and Palette["mail-meta"]
  # both resolve. Raises KeyError on an unknown token, so a typo fails loudly
  # rather than silently rendering an empty colour.
  def self.[](name)
    COLORS.fetch(name.to_s.tr("_", "-"))
  end

  # The CSS `var(--color-…)` reference for a token, for stylesheet-side use.
  def self.css_var(name)
    "var(--color-#{name.to_s.tr('_', '-')})"
  end
end
