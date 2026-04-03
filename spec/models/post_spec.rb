require "rails_helper"

RSpec.describe Post, type: :model do
  describe "validations" do
    it "requires content for published posts" do
      expect(build(:post, content: nil, draft: false)).not_to be_valid
    end

    it "is valid with content" do
      expect(build(:post)).to be_valid
    end

    it "allows nil content for drafts" do
      expect(build(:post, :draft)).to be_valid
    end

    it "enforces one draft per user per scene" do
      existing = create(:post, :draft)
      duplicate = build(:post, :draft, scene: existing.scene, user: existing.user)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to be_present
    end

    it "allows different users to each have a draft in the same scene" do
      existing = create(:post, :draft)
      other = build(:post, :draft, scene: existing.scene, user: create(:user))
      expect(other).to be_valid
    end
  end

  describe "scopes" do
    let!(:published_post) { create(:post, draft: false) }
    let!(:draft_post) { create(:post, :draft) }

    it ".published excludes drafts" do
      expect(Post.published).to include(published_post)
      expect(Post.published).not_to include(draft_post)
    end

    it ".drafts excludes published posts" do
      expect(Post.drafts).to include(draft_post)
      expect(Post.drafts).not_to include(published_post)
    end
  end

  describe "image validation" do
    it "accepts a valid image" do
      post = build(:post)
      post.image.attach(io: File.open(Rails.root.join("spec/fixtures/files/test_image.png")),
                        filename: "test.png", content_type: "image/png")
      expect(post).to be_valid
    end

    it "rejects an image over 10MB" do
      post = build(:post)
      post.image.attach(io: StringIO.new("x" * (11 * 1024 * 1024)),
                        filename: "big.png", content_type: "image/png")
      expect(post).not_to be_valid
      expect(post.errors[:image]).to include("must be less than 10MB")
    end

    it "allows an image exactly 10MB" do
      post = build(:post)
      post.image.attach(io: StringIO.new("x" * 10.megabytes),
                        filename: "exact.png", content_type: "image/png")
      expect(post).to be_valid
    end

    it "rejects a non-image content type" do
      post = build(:post)
      post.image.attach(io: StringIO.new("test"),
                        filename: "doc.pdf", content_type: "application/pdf")
      expect(post).not_to be_valid
      expect(post.errors[:image]).to include("must be a JPEG, PNG, GIF, or WebP image")
    end
  end

  describe "images_allowed_for_game validation" do
    it "rejects image when game has images disabled" do
      game = create(:game, images_disabled: true)
      scene = create(:scene, game: game)
      post = build(:post, scene: scene)
      post.image.attach(io: File.open(Rails.root.join("spec/fixtures/files/test_image.png")),
                        filename: "test.png", content_type: "image/png")
      expect(post).not_to be_valid
      expect(post.errors[:image]).to include("attachments are disabled for this game")
    end

    it "allows image when game has images enabled" do
      game = create(:game, images_disabled: false)
      scene = create(:scene, game: game)
      post = build(:post, scene: scene)
      post.image.attach(io: File.open(Rails.root.join("spec/fixtures/files/test_image.png")),
                        filename: "test.png", content_type: "image/png")
      expect(post).to be_valid
    end

    it "allows post without image when game has images disabled" do
      game = create(:game, images_disabled: true)
      scene = create(:scene, game: game)
      post = build(:post, scene: scene)
      expect(post).to be_valid
    end
  end

  describe "#display_image" do
    it "returns a variant with correct transformations" do
      post = build(:post)
      post.image.attach(io: File.open(Rails.root.join("spec/fixtures/files/test_image.png")),
                        filename: "photo.png", content_type: "image/png")
      result = post.display_image
      expect(result).to be_a(ActiveStorage::VariantWithRecord)
      expect(result.variation.transformations).to eq(
        resize_to_limit: [ 800, nil ], format: :jpeg, quality: 85
      )
    end
  end

  describe "#editable_by?" do
    let(:author) { create(:user) }
    let(:other_user) { create(:user) }

    context "with a 10-minute edit window" do
      let(:game) { create(:game, post_edit_window_minutes: 10) }
      let(:scene) { create(:scene, game: game) }
      let(:post) { create(:post, user: author, scene: scene, created_at: 5.minutes.ago) }

      it "returns true for the author within the window" do
        expect(post.editable_by?(author)).to be true
      end

      it "returns false for a different user" do
        expect(post.editable_by?(other_user)).to be false
      end

      it "returns false after the window has passed" do
        old_post = create(:post, user: author, scene: scene, created_at: 11.minutes.ago)
        expect(old_post.editable_by?(author)).to be false
      end
    end

    context "with no edit window set (forever)" do
      let(:game) { create(:game, post_edit_window_minutes: nil) }
      let(:scene) { create(:scene, game: game) }

      it "returns true for the author regardless of age" do
        old_post = create(:post, user: author, scene: scene, created_at: 1.year.ago)
        expect(old_post.editable_by?(author)).to be true
      end

      it "still returns false for a different user" do
        post = create(:post, user: author, scene: scene)
        expect(post.editable_by?(other_user)).to be false
      end
    end
  end

  describe "#within_edit_window?" do
    context "with a 10-minute edit window" do
      let(:game) { create(:game, post_edit_window_minutes: 10) }
      let(:scene) { create(:scene, game: game) }

      it "returns true for a recent post" do
        expect(create(:post, scene: scene, created_at: 1.minute.ago).within_edit_window?).to be true
      end

      it "returns false for a post past the window" do
        expect(create(:post, scene: scene, created_at: 11.minutes.ago).within_edit_window?).to be false
      end
    end

    context "with no edit window set (forever)" do
      let(:game) { create(:game, post_edit_window_minutes: nil) }
      let(:scene) { create(:scene, game: game) }

      it "returns true regardless of post age" do
        expect(create(:post, scene: scene, created_at: 1.year.ago).within_edit_window?).to be true
      end
    end
  end
end
