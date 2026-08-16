require "rails_helper"

# Versionable::Model is exercised through its original adopter, Character, which
# declares `versions` (character_versions) and `version_attributes`. Described
# as Versionable::Model so mutant attributes these examples to the module
# subject. The behaviour must match what Character had before extraction:
# snapshot on save/save!, roll back on a failed snapshot, and never snapshot on
# touch/update_column.
RSpec.describe Versionable::Model do
  let(:game) { create(:game) }
  let(:user) { create(:user) }

  def character(**overrides)
    build(:character, game: game, user: user, **overrides)
  end

  describe "snapshotting on save" do
    it "writes a version on create" do
      record = character(content: "first")

      expect { record.save }.to change { CharacterVersion.count }.by(1)
    end

    it "writes a version on update" do
      record = character(content: "first").tap(&:save)

      expect { record.update(content: "second") }.to change { CharacterVersion.count }.by(1)
    end

    it "writes a version on save!" do
      record = character(content: "first")

      expect { record.save! }.to change { CharacterVersion.count }.by(1)
    end

    it "captures the current content in the snapshot" do
      record = character(content: "snapshot me").tap(&:save!)

      expect(record.character_versions.last.content).to eq("snapshot me")
    end

    it "does not snapshot when save returns false" do
      record = character(name: nil) # name is required, so save returns false

      expect { record.save }.not_to change { CharacterVersion.count }
      expect(record.save).to be(false)
    end
  end

  describe "paths that bypass snapshotting" do
    it "does not snapshot on touch" do
      record = character(content: "first").tap(&:save!)

      expect { record.touch }.not_to change { CharacterVersion.count }
    end

    it "does not snapshot on update_column" do
      record = character(content: "first").tap(&:save!)

      expect { record.update_column(:content, "sneaky") }.not_to change { CharacterVersion.count }
    end
  end

  describe "transactional rollback" do
    it "rolls the record back when the snapshot fails" do
      record = character(content: "first")
      allow(record).to receive(:version_attributes).and_return({ content: "x", edited_by_id: nil })

      expect { record.save }.to raise_error(ActiveRecord::RecordInvalid)
      expect(Character.where(id: record.id)).to be_empty
    end
  end
end
