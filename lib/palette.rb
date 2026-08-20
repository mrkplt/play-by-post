# typed: true
# frozen_string_literal: true

# Loaded explicitly (not just via Zeitwerk) so bin/build-palette, which runs as
# plain Ruby with no Rails autoloading, still resolves Palette::Groups::ALL.
require_relative "palette/groups"

# The single source of truth for every colour in the application.
#
# Edit colours in lib/palette/groups.rb (Palette::Groups::ALL); this file holds
# the derived flat map and the accessors. Two consumers derive from that data:
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
module Palette
  # The flat token => hex map used by both the generator and the runtime
  # accessor, folded from the grouped Palette::Groups::ALL data.
  COLORS = Groups::ALL.each_with_object({}) do |(_heading, tokens), acc|
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
