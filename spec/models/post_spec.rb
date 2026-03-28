require "rails_helper"

RSpec.describe Post, type: :model do
  describe "validations" do
    it "requires content" do
      expect(build(:post, content: nil)).not_to be_valid
    end

    it "is valid with content" do
      expect(build(:post)).to be_valid
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
    let(:post) { create(:post, user: author, created_at: 5.minutes.ago) }

    it "returns true for the author within the edit window" do
      expect(post.editable_by?(author)).to be true
    end

    it "returns false for a different user" do
      expect(post.editable_by?(other_user)).to be false
    end

    it "returns false after the edit window has passed" do
      old_post = create(:post, user: author, created_at: 11.minutes.ago)
      expect(old_post.editable_by?(author)).to be false
    end
  end

  describe "#within_edit_window?" do
    it "returns true for a recent post" do
      expect(create(:post, created_at: 1.minute.ago).within_edit_window?).to be true
    end

    it "returns false for an old post" do
      expect(create(:post, created_at: 11.minutes.ago).within_edit_window?).to be false
    end
  end
end
