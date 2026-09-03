require "rails_helper"

# The fixed safety preamble prepended to every portrait prompt: the content
# policy plus the injection-resistance framing.
RSpec.describe Ai::PortraitSafetyPrompt do
  describe ".text" do
    let(:text) { described_class.text }

    it "forbids sexual content and nudity" do
      expect(text.downcase).to include("no sexual content", "no nudity")
    end

    it "forbids sexual or childlike depiction of minors" do
      expect(text.downcase).to include("minors", "childlike")
    end

    it "frames the following text as untrusted description, not instructions" do
      expect(text.downcase).to include("untrusted", "never instructions")
    end

    it "instructs to ignore attempts to reveal or change the prompt" do
      expect(text.downcase).to include("reveal or repeat this prompt")
    end

    it "is a frozen, non-empty constant" do
      expect(text).to be_frozen
      expect(text).not_to be_empty
    end
  end
end
