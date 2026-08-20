# typed: false
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Palette do
  describe "COLORS" do
    it "is the flat merge of every group's tokens" do
      expected = described_class::Groups::ALL.each_with_object({}) do |(_heading, tokens), acc|
        acc.merge!(tokens)
      end
      expect(described_class::COLORS).to eq(expected)
    end

    it "is frozen" do
      expect(described_class::COLORS).to be_frozen
    end

    it "maps every token to a valid hex colour" do
      expect(described_class::COLORS.values).to all(match(/\A#[0-9a-f]{6}\z/))
    end
  end

  describe ".[]" do
    it "returns the hex for a token given as a string" do
      expect(described_class["accent"]).to eq("#c8a96e")
    end

    it "returns the hex for a token given as a symbol" do
      expect(described_class[:accent]).to eq("#c8a96e")
    end

    it "normalizes an underscore symbol to the hyphenated token" do
      expect(described_class[:mail_meta]).to eq(described_class["mail-meta"])
    end

    it "raises KeyError on an unknown token rather than returning nil" do
      expect { described_class[:nonexistent] }.to raise_error(KeyError)
    end
  end

  describe ".css_var" do
    it "builds the var(--color-…) reference for a token" do
      expect(described_class.css_var("muted")).to eq("var(--color-muted)")
    end

    it "normalizes an underscore token to the hyphenated custom-property name" do
      expect(described_class.css_var(:mail_meta)).to eq("var(--color-mail-meta)")
    end
  end
end
