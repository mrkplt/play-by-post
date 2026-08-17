# typed: true
# frozen_string_literal: true

# Renders the generated `_palette.css` `@theme` block from Palette::GROUPS.
#
# Depends on Palette. Under Rails both autoload from lib/; the generator bins run
# outside Rails and require both explicitly (see bin/build-palette), so this file
# carries no require of its own — keeping it Zeitwerk-clean (no double-load).
# Kept as a pure function of the palette so both the generator (bin/build-palette)
# and the sync check (bin/check-palette-sync) produce byte-identical output.
module PaletteCss
  HEADER = <<~CSS
    /* GENERATED from lib/palette.rb by bin/build-palette — DO NOT EDIT.
       Add or change a colour in lib/palette.rb, then run bin/build-palette
       (or let assets:precompile / the dev puma plugin regenerate it). */
  CSS

  def self.render
    groups = Palette::GROUPS.map { |heading, tokens| render_group(heading, tokens) }
    body = "@theme {\n#{groups.join("\n\n")}\n}"
    "#{HEADER}\n#{body}\n"
  end

  # The block for one group: the heading comment then one `--color-*`
  # declaration per token, as a single newline-joined string. Groups are
  # separated by a blank line where render joins them.
  def self.render_group(heading, tokens)
    declarations = tokens.map { |token, hex| "  --color-#{token}: #{hex};" }
    [ "  /* #{heading} */", *declarations ].join("\n")
  end
  private_class_method :render_group
end
