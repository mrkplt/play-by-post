require "rails_helper"

RSpec.describe CharacterVersionPresenter do
  let(:version) { build_stubbed(:character_version, created_at: Time.zone.local(2026, 3, 4, 15, 30)) }

  subject(:presenter) { described_class.new(version) }

  describe "#created_at_iso8601" do
    it "formats the timestamp as ISO 8601" do
      expect(presenter.created_at_iso8601).to eq(version.created_at.iso8601)
    end
  end

  describe "#created_at_label" do
    it "formats the timestamp for display" do
      expect(presenter.created_at_label).to eq("Mar 4, 2026 3:30 PM")
    end
  end

  describe "#content?" do
    it "is true when the version has content" do
      expect(described_class.new(build_stubbed(:character_version, content: "some content")).content?).to be(true)
    end

    it "is false when the version has no content" do
      expect(described_class.new(build_stubbed(:character_version, content: "")).content?).to be(false)
    end
  end

  describe "#content" do
    it "returns the version content" do
      version_with_content = build_stubbed(:character_version, content: "Elf ranger, level 5")
      expect(described_class.new(version_with_content).content).to eq("Elf ranger, level 5")
    end
  end

  describe "#editor_name" do
    it "returns the injected editor name" do
      presenter = described_class.new(version, editor_name: "Elrond")
      expect(presenter.editor_name).to eq("Elrond")
    end

    it "raises when no editor name was supplied" do
      expect { presenter.editor_name }.to raise_error(KeyError)
    end
  end
end
