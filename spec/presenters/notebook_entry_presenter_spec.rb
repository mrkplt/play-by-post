require "rails_helper"

RSpec.describe NotebookEntryPresenter do
  describe "#new_record?" do
    it "is true for an unpersisted entry" do
      entry = build_stubbed(:notebook_entry)
      allow(entry).to receive(:new_record?).and_return(true)
      expect(described_class.new(entry).new_record?).to be(true)
    end

    it "is false for a persisted entry" do
      entry = build_stubbed(:notebook_entry)
      allow(entry).to receive(:new_record?).and_return(false)
      expect(described_class.new(entry).new_record?).to be(false)
    end
  end

  describe "#persisted?" do
    it "delegates to the model" do
      entry = build_stubbed(:notebook_entry)
      expect(described_class.new(entry).persisted?).to eq(entry.persisted?)
    end
  end

  describe "#id" do
    it "delegates to the model" do
      entry = build_stubbed(:notebook_entry, id: 42)
      expect(described_class.new(entry).id).to eq(42)
    end
  end

  describe "#title" do
    it "delegates to the model" do
      entry = build_stubbed(:notebook_entry, title: "Idea")
      expect(described_class.new(entry).title).to eq("Idea")
    end
  end

  describe "#errors" do
    it "delegates to the model" do
      entry = build_stubbed(:notebook_entry)
      expect(described_class.new(entry).errors).to eq(entry.errors)
    end
  end
end
