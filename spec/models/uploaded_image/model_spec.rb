require "rails_helper"

# UploadedImage::Model is exercised through an adopter, CharacterImage, which
# declares the has_one_attached, the validate wiring, and owner/siblings.
# Described as UploadedImage::Model so mutant attributes these examples to the
# module subject (the same technique Versionable::Model's spec uses).
RSpec.describe UploadedImage::Model, :db do
  let(:character) { create(:character) }

  def image(**overrides)
    build(:character_image, character: character, **overrides)
  end

  def image_with_file
    build(:character_image, :with_file, character: character)
  end

  describe "#acceptable_image" do
    it "is valid with an acceptable image" do
      expect(image_with_file).to be_valid
    end

    it "is valid with no file attached" do
      expect(image).to be_valid
    end

    it "rejects a file over 10MB with the size message" do
      record = image
      record.file.attach(io: StringIO.new("x" * (10.megabytes + 1)),
                        filename: "big.png", content_type: "image/png")

      expect(record).not_to be_valid
      expect(record.errors[:file]).to eq([ "must be less than 10MB" ])
    end

    it "accepts a file of exactly 10MB (boundary)" do
      record = image
      record.file.attach(io: StringIO.new("x" * 10.megabytes),
                        filename: "exact.png", content_type: "image/png")

      expect(record).to be_valid
    end

    it "rejects a non-image content type with the type message" do
      record = image
      record.file.attach(io: StringIO.new("nope"),
                        filename: "doc.pdf", content_type: "application/pdf")

      expect(record).not_to be_valid
      expect(record.errors[:file]).to eq([ "must be a JPEG, PNG, GIF, or WebP image" ])
    end

    it "accepts each allowed content type" do
      UploadedImage::Model::IMAGE_TYPES.each do |type|
        record = image
        record.file.attach(io: StringIO.new("bytes"), filename: "f", content_type: type)
        expect(record).to be_valid, "expected #{type} to be accepted"
      end
    end
  end

  describe "#display_variant" do
    it "is a 512x512 resize_to_fill jpeg variant at quality 85" do
      result = image_with_file.tap(&:save!).display_variant

      expect(result).to be_a(ActiveStorage::VariantWithRecord)
      expect(result.variation.transformations).to eq(
        resize_to_fill: [ 512, 512 ], format: :jpeg, quality: 85
      )
    end
  end

  describe "#thumbnail_variant" do
    it "is a 96x96 resize_to_fill jpeg variant at quality 85" do
      result = image_with_file.tap(&:save!).thumbnail_variant

      expect(result).to be_a(ActiveStorage::VariantWithRecord)
      expect(result.variation.transformations).to eq(
        resize_to_fill: [ 96, 96 ], format: :jpeg, quality: 85
      )
    end
  end

  describe "#owner" do
    it "is the adopter's owning record" do
      record = create(:character_image, character: character)
      expect(record.owner).to eq(character)
    end
  end

  describe "#siblings" do
    it "is the owner's other images, excluding self" do
      first = create(:character_image, character: character)
      second = create(:character_image, character: character)
      other_owner_image = create(:character_image)

      expect(first.siblings).to contain_exactly(second)
      expect(first.siblings).not_to include(first, other_owner_image)
    end
  end

  describe "#make_current!" do
    it "sets this image current" do
      record = create(:character_image, character: character)

      record.make_current!

      expect(record.reload.current?).to be(true)
    end

    it "clears the flag on the owner's other images" do
      first = create(:character_image, :current, character: character)
      second = create(:character_image, character: character)

      second.make_current!

      expect(first.reload.current?).to be(false)
      expect(second.reload.current?).to be(true)
    end

    it "does not touch another owner's current image" do
      mine = create(:character_image, character: character)
      theirs = create(:character_image, :current)

      mine.make_current!

      expect(theirs.reload.current?).to be(true)
    end

    it "rolls back both writes if the transaction fails" do
      first = create(:character_image, :current, character: character)
      record = create(:character_image, character: character)
      allow(record).to receive(:update!).and_raise(ActiveRecord::RecordInvalid.new(record))

      expect { record.make_current! }.to raise_error(ActiveRecord::RecordInvalid)
      # The sibling clear is inside the same transaction, so first stays current.
      expect(first.reload.current?).to be(true)
    end
  end
end
