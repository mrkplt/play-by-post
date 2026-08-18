# Shared behaviour every UploadedImage::Model adopter carries: the file
# validations, the square display/thumbnail variants, and the make_current!
# exclusivity. Both CharacterImage and UserImage exercise it, passing their
# factory name so the group stays owner-agnostic.
#
# Usage:
#   it_behaves_like "an uploaded image", :character_image
RSpec.shared_examples "an uploaded image" do |factory_name|
  subject(:image) { build(factory_name) }

  describe "file validation" do
    it "is valid with an acceptable image" do
      image = build(factory_name, :with_file)
      expect(image).to be_valid
    end

    it "is valid with no file attached" do
      expect(image).to be_valid
    end

    it "rejects a file over 10MB" do
      image.file.attach(io: StringIO.new("x" * (11 * 1024 * 1024)),
                        filename: "big.png", content_type: "image/png")
      expect(image).not_to be_valid
      expect(image.errors[:file]).to include("must be less than 10MB")
    end

    it "allows a file exactly 10MB" do
      image.file.attach(io: StringIO.new("x" * 10.megabytes),
                        filename: "exact.png", content_type: "image/png")
      expect(image).to be_valid
    end

    it "rejects a non-image content type" do
      image.file.attach(io: StringIO.new("nope"),
                        filename: "doc.pdf", content_type: "application/pdf")
      expect(image).not_to be_valid
      expect(image.errors[:file]).to include("must be a JPEG, PNG, GIF, or WebP image")
    end
  end

  describe "#display_variant" do
    it "returns a 512px square jpeg variant" do
      image = build(factory_name, :with_file)
      result = image.display_variant
      expect(result).to be_a(ActiveStorage::VariantWithRecord)
      expect(result.variation.transformations).to eq(
        resize_to_fill: [ 512, 512 ], format: :jpeg, quality: 85
      )
    end
  end

  describe "#thumbnail_variant" do
    it "returns a 96px square jpeg variant" do
      image = build(factory_name, :with_file)
      result = image.thumbnail_variant
      expect(result).to be_a(ActiveStorage::VariantWithRecord)
      expect(result.variation.transformations).to eq(
        resize_to_fill: [ 96, 96 ], format: :jpeg, quality: 85
      )
    end
  end

  describe "#make_current!", :db do
    it "marks this image current" do
      image = create(factory_name)
      image.make_current!
      expect(image.reload.current?).to be(true)
    end

    it "clears the flag on the owner's other images" do
      first = create(factory_name, :current)
      owner = first.owner
      second = create(factory_name, owner_key(factory_name) => owner)

      second.make_current!

      expect(first.reload.current?).to be(false)
      expect(second.reload.current?).to be(true)
    end

    it "leaves another owner's current image untouched" do
      mine = create(factory_name)
      theirs = create(factory_name, :current)

      mine.make_current!

      expect(theirs.reload.current?).to be(true)
    end
  end

  # The association key a sibling shares with its owner, so a second image can be
  # built for the same owner as the first.
  def owner_key(factory_name)
    factory_name == :character_image ? :character : :user
  end
end
