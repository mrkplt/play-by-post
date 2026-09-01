require "rails_helper"

RSpec.describe GameExport::Slug do
  describe ".call" do
    it "lowercases and hyphenates" do
      expect(described_class.call("The Sunken Archive")).to eq("the-sunken-archive")
    end

    it "strips punctuation" do
      expect(described_class.call("Chapter 1: The End!")).to eq("chapter-1-the-end")
    end

    it "collapses repeated separators" do
      expect(described_class.call("a   -  b")).to eq("a-b")
    end

    it "trims leading and trailing hyphens" do
      expect(described_class.call("-edge-")).to eq("edge")
    end

    it "keeps digits" do
      expect(described_class.call("Act 2")).to eq("act-2")
    end

    it "falls back to untitled when nothing survives" do
      expect(described_class.call("!!!")).to eq("untitled")
    end

    it "falls back to untitled for an empty title" do
      expect(described_class.call("")).to eq("untitled")
    end
  end

  describe ".unique_filename" do
    it "slugs the stem but preserves the extension" do
      expect(described_class.unique_filename("My Map.PDF", {})).to eq("my-map.pdf")
    end

    it "lowercases the extension" do
      expect(described_class.unique_filename("photo.JPEG", {})).to eq("photo.jpeg")
    end

    it "slugs a name with no extension" do
      expect(described_class.unique_filename("Session Notes", {})).to eq("session-notes")
    end

    it "falls back to untitled for a stem that slugs to nothing, keeping the extension" do
      expect(described_class.unique_filename("!!!.pdf", {})).to eq("untitled.pdf")
    end

    it "handles a name with multiple dots, splitting only the final extension" do
      expect(described_class.unique_filename("archive.tar.gz", {})).to eq("archivetar.gz")
    end

    it "inserts the ordinal before the extension for a repeat" do
      tracker = {}
      described_class.unique_filename("notes.txt", tracker)

      expect(described_class.unique_filename("Notes.txt", tracker)).to eq("notes-2.txt")
    end

    it "de-duplicates extensionless repeats too" do
      tracker = {}
      described_class.unique_filename("Session Notes", tracker)

      expect(described_class.unique_filename("session notes", tracker)).to eq("session-notes-2")
    end
  end

  describe ".unique" do
    it "returns the base the first time it is seen" do
      expect(described_class.unique("ambush", {})).to eq("ambush")
    end

    it "suffixes the second occurrence" do
      tracker = {}
      described_class.unique("ambush", tracker)

      expect(described_class.unique("ambush", tracker)).to eq("ambush-2")
    end

    it "keeps counting past the second" do
      tracker = {}
      3.times { described_class.unique("ambush", tracker) }

      expect(described_class.unique("ambush", tracker)).to eq("ambush-4")
    end

    it "counts each base separately" do
      tracker = {}
      described_class.unique("ambush", tracker)

      expect(described_class.unique("escape", tracker)).to eq("escape")
    end

    it "records what it has seen in the tracker" do
      tracker = {}
      described_class.unique("ambush", tracker)

      expect(tracker).to eq({ "ambush" => 1 })
    end
  end
end
