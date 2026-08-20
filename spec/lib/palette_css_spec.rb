# typed: false
# frozen_string_literal: true

require "rails_helper"

RSpec.describe PaletteCss do
  describe ".render" do
    subject(:css) { described_class.render }

    it "opens with the generated-file header" do
      expect(css).to start_with("/* GENERATED from lib/palette.rb")
    end

    it "wraps the tokens in a single @theme block" do
      expect(css).to include("@theme {")
      expect(css.scan("@theme {").size).to eq(1)
      expect(css).to end_with("}\n")
    end

    it "emits a --color-* declaration for every palette token" do
      Palette::COLORS.each do |token, hex|
        expect(css).to include("  --color-#{token}: #{hex};")
      end
    end

    it "reproduces each group heading as a comment" do
      Palette::Groups::ALL.each do |heading, _tokens|
        expect(css).to include("  /* #{heading} */")
      end
    end

    it "separates groups with a blank line but does not lead with one" do
      body = css.sub(described_class::HEADER, "").sub(/\A\n/, "")
      expect(body).to start_with("@theme {\n  /*")
    end

    it "puts a blank line between one group's last declaration and the next group's heading" do
      first_heading, first_tokens = Palette::Groups::ALL.first
      second_heading = Palette::Groups::ALL[1].first
      last_token, last_hex = first_tokens.to_a.last
      # The trailing declaration of the first group, a blank line, then the
      # second group's heading — the "\n\n" separator join produces exactly this.
      expect(css).to include("  --color-#{last_token}: #{last_hex};\n\n  /* #{second_heading} */")
      expect(first_heading).to be_present
    end

    it "is deterministic" do
      expect(described_class.render).to eq(css)
    end
  end
end
