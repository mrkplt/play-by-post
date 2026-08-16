require "rails_helper"

RSpec.describe PageVersionPresenter do
  let(:editor) { build_stubbed(:user, email: "gandalf@example.com") }
  let(:version) do
    build_stubbed(:page_version, edited_by: editor, title: "Lore", body: "the tale",
                                 created_at: Time.utc(2026, 1, 2, 15, 4))
  end

  subject(:presenter) { described_class.new(version) }

  describe "#title" do
    it "returns the version's title" do
      expect(presenter.title).to eq("Lore")
    end
  end

  describe "#body" do
    it "returns the version's body" do
      expect(presenter.body).to eq("the tale")
    end
  end

  describe "#body?" do
    it "is true when body is present" do
      expect(presenter.body?).to be(true)
    end

    it "is false when body is blank" do
      blank = build_stubbed(:page_version, edited_by: editor, body: nil)
      expect(described_class.new(blank).body?).to be(false)
    end
  end

  describe "#formatted_created_at" do
    it "renders the human-readable timestamp" do
      expect(presenter.formatted_created_at).to eq("Jan 2, 2026 3:04 PM")
    end
  end

  describe "#created_at_timestamp" do
    it "renders the ISO 8601 timestamp" do
      expect(presenter.created_at_timestamp).to eq(version.created_at.iso8601)
    end
  end

  describe "#editor_name" do
    it "returns the editor's display name via UserPresenter" do
      expect(presenter.editor_name).to eq(UserPresenter.new(editor).display_name_or_email)
    end
  end
end
