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

    it "declares one draft per user per scene" do
      validator = Post.validators_on(:user_id)
        .find { |v| v.is_a?(ActiveRecord::Validations::UniquenessValidator) }

      expect(validator.options[:scope]).to eq(:scene_id)
      expect(validator.options[:if]).to eq(:draft?)
    end

    it "allows different users to each have a draft in the same scene" do
      existing = create(:post, :draft)
      other = build(:post, :draft, scene: existing.scene, user: create(:user))
      expect(other).to be_valid
    end
  end

  describe "scopes" do
    it ".published selects only non-drafts" do
      expect(Post.published.where_values_hash).to eq("draft" => false)
    end

    it ".drafts selects only drafts" do
      expect(Post.drafts.where_values_hash).to eq("draft" => true)
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

  # Both predicates read the window through #game, so stubbing that covers every
  # branch without persisting a game, a scene and a post per example.
  describe "#editable_by?" do
    let(:author) { build_stubbed(:user) }
    let(:other_user) { build_stubbed(:user) }

    def post_by(author_user, window:, age: 1.minute)
      post = build_stubbed(:post, user: author_user, created_at: age.ago)
      allow(post).to receive(:game).and_return(double(edit_window_duration: window))
      post
    end

    context "with a 10-minute edit window" do
      it "returns true for the author within the window" do
        expect(post_by(author, window: 10.minutes, age: 5.minutes).editable_by?(author)).to be true
      end

      it "returns false after the window has passed" do
        expect(post_by(author, window: 10.minutes, age: 11.minutes).editable_by?(author)).to be false
      end

      it "returns false for a different user" do
        expect(post_by(author, window: 10.minutes).editable_by?(other_user)).to be false
      end
    end

    context "with no edit window set (forever)" do
      it "returns true for the author regardless of age" do
        expect(post_by(author, window: nil, age: 1.year).editable_by?(author)).to be true
      end

      it "still returns false for a different user" do
        expect(post_by(author, window: nil).editable_by?(other_user)).to be false
      end
    end
  end

  describe "#within_edit_window?" do
    def post_aged(age, window:)
      post = build_stubbed(:post, created_at: age.ago)
      allow(post).to receive(:game).and_return(double(edit_window_duration: window))
      post
    end

    context "with a 10-minute edit window" do
      it "returns true for a recent post" do
        expect(post_aged(1.minute, window: 10.minutes).within_edit_window?).to be true
      end

      it "returns false for a post past the window" do
        expect(post_aged(11.minutes, window: 10.minutes).within_edit_window?).to be false
      end

      it "returns false exactly at the window boundary" do
        expect(post_aged(10.minutes, window: 10.minutes).within_edit_window?).to be false
      end
    end

    context "with no edit window set (forever)" do
      it "returns true regardless of post age" do
        expect(post_aged(1.year, window: nil).within_edit_window?).to be true
      end
    end
  end
end
