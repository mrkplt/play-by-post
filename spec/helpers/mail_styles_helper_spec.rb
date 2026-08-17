# typed: false
# frozen_string_literal: true

require "rails_helper"

RSpec.describe MailStylesHelper, type: :helper do
  describe "#mail_meta_style" do
    it "sets the muted meta colour from the palette" do
      expect(helper.mail_meta_style).to eq("color:#{Palette[:mail_meta]}")
    end

    it "appends a font-size when given" do
      expect(helper.mail_meta_style(size: "0.8em"))
        .to eq("color:#{Palette[:mail_meta]}; font-size:0.8em")
    end

    it "appends extra declarations verbatim" do
      expect(helper.mail_meta_style(extra: "margin:0 0 0.25rem"))
        .to eq("color:#{Palette[:mail_meta]}; margin:0 0 0.25rem")
    end

    it "orders colour, size, then extra when all are given" do
      expect(helper.mail_meta_style(size: "0.85em", extra: "margin:0"))
        .to eq("color:#{Palette[:mail_meta]}; font-size:0.85em; margin:0")
    end
  end

  describe "#mail_rule_style" do
    it "draws the digest border rule from the palette" do
      expect(helper.mail_rule_style).to include("border-left:3px solid #{Palette[:mail_rule]}")
      expect(helper.mail_rule_style).to include("padding-left:1rem")
      expect(helper.mail_rule_style).to include("margin-bottom:1rem")
    end
  end

  describe "#mail_button_style" do
    it "paints the CTA button background from the palette" do
      expect(helper.mail_button_style).to include("background:#{Palette[:mail_action]}")
      expect(helper.mail_button_style).to include("color:white")
      expect(helper.mail_button_style).to include("font-weight:600")
    end
  end
end
