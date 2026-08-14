require "rails_helper"

RSpec.describe CharacterVersionPresenter do
  let(:editor) { build_stubbed(:user, email: "gandalf@example.com") }
  let(:version) do
    build_stubbed(:character_version, edited_by: editor, content: "Version content",
                                       created_at: Time.utc(2026, 1, 2, 15, 4))
  end

  subject(:presenter) { described_class.new(version) }

  describe "#created_at" do
    it "returns the version's created_at" do
      expect(presenter.created_at).to eq(version.created_at)
    end
  end

  describe "#content" do
    it "returns the version's content" do
      expect(presenter.content).to eq("Version content")
    end
  end

  describe "#content?" do
    it "is true when content is present" do
      expect(presenter.content?).to be(true)
    end

    it "is false when content is blank" do
      blank_version = build_stubbed(:character_version, edited_by: editor, content: nil)
      expect(described_class.new(blank_version).content?).to be(false)
    end
  end

  describe "#formatted_created_at" do
    it "formats the timestamp for display" do
      expect(presenter.formatted_created_at).to eq("Jan 2, 2026 3:04 PM")
    end
  end

  describe "#created_at_timestamp" do
    it "formats the timestamp as iso8601" do
      expect(presenter.created_at_timestamp).to eq(version.created_at.iso8601)
    end
  end

  describe "#editor_name" do
    it "delegates to UserPresenter for the editor's display name" do
      allow(editor).to receive(:display_name).and_return(nil)
      expect(presenter.editor_name).to eq("gandalf")
    end

    it "prefers the editor's display name when present" do
      allow(editor).to receive(:display_name).and_return("Gandalf the Grey")
      expect(presenter.editor_name).to eq("Gandalf the Grey")
    end
  end
end
