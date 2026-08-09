require "rails_helper"

RSpec.describe NotebookEntry do
  describe "associations" do
    it "belongs to a game" do
      expect(described_class.reflect_on_association(:game).macro).to eq(:belongs_to)
    end

    it "belongs to an optional promoted page" do
      reflection = described_class.reflect_on_association(:promoted_page)
      expect(reflection.macro).to eq(:belongs_to)
      expect(reflection.options[:optional]).to be(true)
      expect(reflection.options[:class_name]).to eq("Page")
    end
  end

  describe "validations" do
    it "requires a title" do
      entry = build(:notebook_entry, title: nil)
      expect(entry).not_to be_valid
      expect(entry.errors[:title]).to be_present
    end

    it "rejects a title longer than 200 characters" do
      entry = build(:notebook_entry, title: "a" * 201)
      expect(entry).not_to be_valid
      expect(entry.errors[:title]).to be_present
    end

    it "allows a blank body" do
      entry = build(:notebook_entry, body: nil)
      entry.valid?
      expect(entry.errors[:body]).to be_empty
    end

    it "defaults status to new" do
      entry = described_class.new
      expect(entry.status).to eq("new")
    end

    NotebookEntry::STATUSES.each do |status|
      it "allows status #{status.inspect}" do
        entry = build(:notebook_entry, status: status)
        entry.valid?
        expect(entry.errors[:status]).to be_empty
      end
    end

    it "rejects a status outside the allowed list" do
      entry = build(:notebook_entry, status: "bogus")
      expect(entry).not_to be_valid
      expect(entry.errors[:status]).to be_present
    end
  end

  describe "slug generation" do
    it "assigns a 16-character alphanumeric slug on create" do
      entry = build(:notebook_entry, slug: nil)
      entry.valid?
      expect(entry.slug).to match(/\A[a-zA-Z0-9]{16}\z/)
    end

    it "does not overwrite a slug that is already present" do
      entry = build(:notebook_entry, slug: "existingslug1234")
      entry.valid?
      expect(entry.slug).to eq("existingslug1234")
    end

    it "only generates on create, leaving an edited record's slug untouched", db: true do
      entry = create(:notebook_entry)
      original = entry.slug
      entry.update!(title: "Renamed")
      expect(entry.reload.slug).to eq(original)
    end

    it "generates a fresh slug each call" do
      expect(described_class.generate_secure_slug).not_to eq(described_class.generate_secure_slug)
    end
  end

  describe "#to_param" do
    it "routes by slug, not id" do
      entry = build(:notebook_entry, slug: "abc123def456ghij")
      expect(entry.to_param).to eq("abc123def456ghij")
    end
  end

  describe "#promoted?" do
    it "is false when there is no promoted page" do
      entry = build(:notebook_entry, promoted_page_id: nil)
      expect(entry.promoted?).to be(false)
    end

    it "is true once a promoted page id is set" do
      entry = build(:notebook_entry, promoted_page_id: 42)
      expect(entry.promoted?).to be(true)
    end
  end
end
