require "rails_helper"

RSpec.describe Page do
  describe "associations" do
    it "belongs to a game" do
      expect(described_class.reflect_on_association(:game).macro).to eq(:belongs_to)
    end

    it "nullifies promoted-from notebook entries on destroy" do
      association = described_class.reflect_on_association(:promoted_from_entries)
      expect(association.macro).to eq(:has_many)
      expect(association.options[:dependent]).to eq(:nullify)
      expect(association.options[:foreign_key]).to eq(:promoted_page_id)
    end
  end

  describe "validations" do
    it "requires a title" do
      page = build(:page, title: nil)
      expect(page).not_to be_valid
      expect(page.errors[:title]).to be_present
    end

    it "rejects a title longer than 200 characters" do
      page = build(:page, title: "a" * 201)
      expect(page).not_to be_valid
      expect(page.errors[:title]).to be_present
    end

    it "allows a blank body" do
      page = build(:page, body: nil)
      page.valid?
      expect(page.errors[:body]).to be_empty
    end
  end

  describe "slug generation" do
    it "assigns a 16-character alphanumeric slug on create" do
      page = build(:page, slug: nil)
      page.valid?
      expect(page.slug).to match(/\A[a-zA-Z0-9]{16}\z/)
    end

    it "does not overwrite a slug that is already present" do
      page = build(:page, slug: "existingslug1234")
      page.valid?
      expect(page.slug).to eq("existingslug1234")
    end

    it "only generates on create, leaving an edited record's slug untouched", db: true do
      page = create(:page)
      original = page.slug
      page.update!(title: "Renamed")
      expect(page.reload.slug).to eq(original)
    end

    it "generates a fresh slug each call" do
      expect(described_class.generate_secure_slug).not_to eq(described_class.generate_secure_slug)
    end
  end

  describe "#to_param" do
    it "routes by slug, not id" do
      page = build(:page, slug: "abc123def456ghij")
      expect(page.to_param).to eq("abc123def456ghij")
    end
  end
end
