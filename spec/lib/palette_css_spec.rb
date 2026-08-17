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
      Palette::GROUPS.each do |heading, _tokens|
        expect(css).to include("  /* #{heading} */")
      end
    end

    it "separates groups with a blank line but does not lead with one" do
      body = css.sub(described_class::HEADER, "").sub(/\A\n/, "")
      expect(body).to start_with("@theme {\n  /*")
    end

    it "is deterministic" do
      expect(described_class.render).to eq(css)
    end
  end
end
