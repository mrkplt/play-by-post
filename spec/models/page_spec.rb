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
    it "requires a title when published" do
      page = build(:page, title: nil, draft: false)
      expect(page).not_to be_valid
      expect(page.errors[:title]).to be_present
    end

    it "allows a blank title when a draft" do
      page = build(:page, title: nil, draft: true)
      page.valid?
      expect(page.errors[:title]).to be_empty
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

  describe "versioning" do
    it "has many page versions destroyed with the page" do
      association = described_class.reflect_on_association(:page_versions)
      expect(association.macro).to eq(:has_many)
      expect(association.options[:dependent]).to eq(:destroy)
    end

    it "snapshots title, body, and editor on save" do
      editor = create(:user)
      page = create(:page, title: "Lore", body: "the tale", editor: editor)

      version = page.page_versions.last
      expect(version.title).to eq("Lore")
      expect(version.body).to eq("the tale")
      expect(version.edited_by).to eq(editor)
    end

    it "attributes a version to the acting Current.user on update" do
      page = create(:page)
      editor = create(:user)
      Current.user = editor

      expect { page.update!(title: "Revised") }.to change { page.page_versions.count }.by(1)
      expect(page.page_versions.last.edited_by).to eq(editor)
    end
  end

  describe "draft scopes" do
    it ".published selects only non-drafts" do
      expect(described_class.published.where_values_hash).to eq("draft" => false)
    end

    it ".drafts selects only drafts" do
      expect(described_class.drafts.where_values_hash).to eq("draft" => true)
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
      Current.user = create(:user) # a page save snapshots a version attributed to the editor
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

  # Authorship is the editor of the earliest version, which never changes as
  # later revisions accrue — so a page edited by someone else is still created
  # by its original author (Fizzy #18 delete-own gate).
  describe "#created_by?" do
    it "is true for the author of the earliest version" do
      author = create(:user)
      page = create(:page, editor: author)

      Current.user = create(:user)
      page.update!(title: "Edited by someone else")

      expect(page.created_by?(author)).to be(true)
    end

    it "is false for a later editor who did not create the page" do
      author = create(:user)
      later_editor = create(:user)
      page = create(:page, editor: author)

      Current.user = later_editor
      page.update!(title: "Edited later")

      expect(page.created_by?(later_editor)).to be(false)
    end

    it "is false for an unrelated user" do
      page = create(:page, editor: create(:user))
      expect(page.created_by?(create(:user))).to be(false)
    end

    # A page with no versions yet (an unsaved record) is authored by nobody —
    # the earliest-version lookup is nil, so created_by? is false rather than
    # raising. Guards the safe-navigation in the lookup.
    it "is false for a page that has no versions yet" do
      page = build(:page)
      expect(page.page_versions).to be_empty
      expect(page.created_by?(create(:user))).to be(false)
    end

    # Authorship is the *earliest by created_at*, not merely the first row the DB
    # happens to return. Insert a second version whose created_at is EARLIER than
    # the original but which is inserted LATER: the earliest-timestamp editor
    # (here `earlier`) is the author, provable only if the row is chosen by
    # created_at and not by insertion order — which kills the dropped-`order`
    # mutant.
    it "chooses the earliest version by timestamp, not insertion order" do
      original_editor = create(:user)
      earlier = create(:user)
      page = create(:page, editor: original_editor)

      first_version = page.page_versions.first
      page.page_versions.create!(
        title: page.title, body: page.body, edited_by: earlier,
        created_at: first_version.created_at - 1.day
      )

      expect(page.created_by?(earlier)).to be(true)
      expect(page.created_by?(original_editor)).to be(false)
    end
  end
end
