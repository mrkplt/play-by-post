require "rails_helper"

RSpec.describe NotebookEntryPresenter do
  let(:game) { build_stubbed(:game) }
  let(:entry) { build_stubbed(:notebook_entry, game: game, title: "Idea", slug: "abc123def456ghij", status: "new") }

  subject(:presenter) { described_class.new(entry) }

  describe "#title" do
    it "returns the entry's title" do
      expect(presenter.title).to eq("Idea")
    end
  end

  describe "#slug" do
    it "returns the entry's slug" do
      expect(presenter.slug).to eq("abc123def456ghij")
    end
  end

  describe "#status" do
    it "returns the entry's status" do
      expect(presenter.status).to eq("new")
    end
  end

  describe "#status_previously_was" do
    it "reports the entry's prior status after a move" do
      allow(entry).to receive(:status_previously_was).and_return("new")
      expect(presenter.status_previously_was).to eq("new")
    end

    it "is nil for an entry that has not changed status" do
      allow(entry).to receive(:status_previously_was).and_return(nil)
      expect(presenter.status_previously_was).to be_nil
    end
  end

  describe "#new_record?" do
    it "is true for an unpersisted entry" do
      expect(described_class.new(game.notebook_entries.new).new_record?).to be(true)
    end

    it "is false for a persisted entry" do
      expect(presenter.new_record?).to be(false)
    end
  end

  describe "#id" do
    it "returns the entry's id" do
      expect(presenter.id).to eq(entry.id)
    end
  end

  describe "#errors?" do
    it "is false on a clean entry" do
      expect(presenter.errors?).to be(false)
    end

    it "is true once a validation error is added" do
      entry.errors.add(:title, "can't be blank")
      expect(presenter.errors?).to be(true)
    end
  end

  describe "#error_messages" do
    it "returns the entry's full validation messages" do
      entry.errors.add(:title, "can't be blank")
      expect(presenter.error_messages).to include("Title can't be blank")
    end
  end

  describe "#promoted?" do
    it "is false for an entry with no promoted page" do
      expect(presenter.promoted?).to be(false)
    end

    it "is true once the entry has a promoted page" do
      promoted = build_stubbed(:notebook_entry, game: game,
                               promoted_page: build_stubbed(:page, game: game))
      expect(described_class.new(promoted).promoted?).to be(true)
    end
  end

  describe "#promoted_page_title" do
    it "returns the promoted page's title" do
      page = build_stubbed(:page, game: game, title: "The Sunken Temple")
      promoted = build_stubbed(:notebook_entry, game: game, promoted_page: page)

      expect(described_class.new(promoted).promoted_page_title).to eq("The Sunken Temple")
    end
  end

  describe "#promoted_page_slug" do
    it "returns the promoted page's slug" do
      page = build_stubbed(:page, game: game, slug: "temple0000000000")
      promoted = build_stubbed(:notebook_entry, game: game, promoted_page: page)

      expect(described_class.new(promoted).promoted_page_slug).to eq("temple0000000000")
    end
  end

  it "delegates model methods to the entry" do
    expect(presenter.body).to eq(entry.body)
  end
end
