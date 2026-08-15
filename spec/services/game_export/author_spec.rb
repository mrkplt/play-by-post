require "rails_helper"

RSpec.describe GameExport::Author do
  describe ".name_for" do
    it "uses the display name when set" do
      user = double(display_name: "Dana", email: "dana@example.com")

      expect(described_class.name_for(user)).to eq("Dana")
    end

    it "falls back to the email when the display name is blank" do
      user = double(display_name: "", email: "dana@example.com")

      expect(described_class.name_for(user)).to eq("dana@example.com")
    end

    it "falls back to the email when the display name is nil" do
      user = double(display_name: nil, email: "dana@example.com")

      expect(described_class.name_for(user)).to eq("dana@example.com")
    end
  end
end
