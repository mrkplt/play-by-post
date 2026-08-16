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

  describe "versioning" do
    it "has many notebook entry versions destroyed with the entry" do
      association = described_class.reflect_on_association(:notebook_entry_versions)
      expect(association.macro).to eq(:has_many)
      expect(association.options[:dependent]).to eq(:destroy)
    end

    it "snapshots title, body, and editor on save", db: true do
      editor = create(:user)
      entry = create(:notebook_entry, title: "Lore", body: "the tale", editor: editor)

      version = entry.notebook_entry_versions.last
      expect(version.title).to eq("Lore")
      expect(version.body).to eq("the tale")
      expect(version.edited_by).to eq(editor)
    end

    it "attributes a version to the acting Current.user on update", db: true do
      entry = create(:notebook_entry)
      editor = create(:user)
      Current.user = editor

      expect { entry.update!(title: "Revised") }.to change { entry.notebook_entry_versions.count }.by(1)
      expect(entry.notebook_entry_versions.last.edited_by).to eq(editor)
    ensure
      Current.user = nil
    end

    describe "#version_attributes" do
      it "captures only title and body — not status or promotion" do
        entry = build(:notebook_entry, title: "T", body: "B", status: "done", promoted_page_id: 7)
        expect(entry.version_attributes.keys).to contain_exactly(:title, :body, :edited_by_id)
      end

      it "reads attribution from Current.user" do
        user = build_stubbed(:user)
        Current.user = user
        entry = build(:notebook_entry)
        expect(entry.version_attributes[:edited_by_id]).to eq(user.id)
      ensure
        Current.user = nil
      end

      it "falls back to nil attribution when there is no current user" do
        Current.user = nil
        entry = build(:notebook_entry)
        expect(entry.version_attributes[:edited_by_id]).to be_nil
      end
    end

    describe "#versions" do
      it "is the notebook_entry_versions association" do
        entry = build(:notebook_entry)
        expect(entry.versions).to eq(entry.notebook_entry_versions)
      end
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
      Current.user = create(:user) # an entry save snapshots a version attributed to the editor
      entry.update!(title: "Renamed")
      expect(entry.reload.slug).to eq(original)
    ensure
      Current.user = nil
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
