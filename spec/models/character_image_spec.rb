require "rails_helper"

RSpec.describe CharacterImage, type: :model do
  it_behaves_like "an uploaded image", :character_image

  describe "#owner" do
    it "is the character" do
      character = build(:character)
      image = build(:character_image, character: character)
      expect(image.owner).to eq(character)
    end
  end

  describe "#siblings", :db do
    it "is the character's other images, excluding self" do
      character = create(:character)
      first = create(:character_image, character: character)
      second = create(:character_image, character: character)
      other_character_image = create(:character_image)

      expect(first.siblings).to contain_exactly(second)
      expect(first.siblings).not_to include(first, other_character_image)
    end
  end

  describe "generation state", :db do
    let(:character) { create(:character) }

    it "allows a fileless skeleton (pending) — the image validation is conditional" do
      skeleton = character.character_images.create!
      expect(skeleton).to be_pending
      expect(skeleton).not_to be_failed
      expect(skeleton.ai_generated?).to be(false)
    end

    describe "#complete_generation!" do
      it "attaches the file and stamps AI provenance, ending the pending state" do
        skeleton = character.character_images.create!

        skeleton.complete_generation!({ io: StringIO.new("\x89PNG".b), filename: "p.png", content_type: "image/png" })

        expect(skeleton.file).to be_attached
        expect(skeleton.ai_generated?).to be(true)
        expect(skeleton).not_to be_pending
      end
    end

    describe "#fail_generation!" do
      it "marks the skeleton failed with a player-facing reason" do
        skeleton = character.character_images.create!

        skeleton.fail_generation!("blocked")

        expect(skeleton).to be_failed
        expect(skeleton.failure_reason).to eq("blocked")
        expect(skeleton).not_to be_pending
      end
    end

    describe "scopes" do
      it "ready: only file-attached rows; pending: fileless not-failed; failed: failed rows" do
        ready = create(:character_image, :with_file, character: character)
        pending = character.character_images.create!
        failed = character.character_images.create!.tap { |i| i.fail_generation!("x") }

        expect(character.character_images.ready).to contain_exactly(ready)
        expect(character.character_images.pending).to contain_exactly(pending)
        expect(character.character_images.failed).to contain_exactly(failed)
      end
    end
  end
end
