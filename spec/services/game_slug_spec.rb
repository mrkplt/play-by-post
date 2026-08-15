require "rails_helper"

RSpec.describe GameSlug do
  describe ".build" do
    it "derives a hyphenated base from the name and appends a random suffix" do
      expect(described_class.build("Dragons of Icespire Peak"))
        .to match(/\Adragons-of-icespire-peak-[a-z0-9]{6}\z/)
    end

    it "returns a bare suffix when the name parameterizes to empty" do
      expect(described_class.build("日本語")).to match(/\A[a-z0-9]{6}\z/)
    end

    it "treats a nil name as empty rather than raising" do
      expect(described_class.build(nil)).to match(/\A[a-z0-9]{6}\z/)
    end

    it "produces a distinct slug on each call so same-named games never collide" do
      expect(described_class.build("Same Name")).not_to eq(described_class.build("Same Name"))
    end
  end

  describe ".generate_suffix" do
    it "is a lowercase alphanumeric string of the configured length" do
      expect(described_class.generate_suffix).to match(/\A[a-z0-9]{#{GameSlug::SUFFIX_LENGTH}}\z/)
    end

    it "generates a distinct suffix each call" do
      expect(described_class.generate_suffix).not_to eq(described_class.generate_suffix)
    end
  end
end
