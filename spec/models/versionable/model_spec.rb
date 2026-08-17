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

  describe "attribution derived from version history" do
    let(:creator) { create(:user) }
    let(:later_editor) { create(:user) }

    # Character#version_attributes falls back to the record's owner when
    # Current.user is nil, so setting Current.user before each save pins a
    # distinct editor onto each version — creator on create, later_editor on the
    # update.
    def with_current(editor)
      previous = Current.user
      Current.user = editor
      yield
    ensure
      Current.user = previous
    end

    # The second version is backdated so its created_at precedes the first
    # version's while it is still inserted last. That divorces created_at order
    # from insertion order, so a reader that dropped the explicit
    # `order(:created_at)` and leaned on default (id/insertion) order would pick
    # the wrong version — pinning both the earliest-by-time and latest-by-time
    # attributions.
    it "created_by_id is the editor of the earliest version by time, not insertion order" do
      record = nil
      with_current(creator) { record = character(content: "first").tap(&:save!) }
      Timecop.freeze(2.days.ago) do
        with_current(later_editor) { record.update!(content: "second") }
      end

      expect(record.created_by_id).to eq(later_editor.id)
    end

    it "last_edited_by_id is the editor of the latest version by time, not insertion order" do
      record = nil
      with_current(creator) { record = character(content: "first").tap(&:save!) }
      Timecop.freeze(2.days.ago) do
        with_current(later_editor) { record.update!(content: "second") }
      end

      # `creator`'s version is the newest by time but was inserted first, so a
      # reader leaning on insertion order would wrongly return `later_editor`.
      expect(record.last_edited_by_id).to eq(creator.id)
    end

    it "created_by_id does not change when a later edit is added" do
      record = nil
      with_current(creator) { record = character(content: "first").tap(&:save!) }
      with_current(later_editor) { record.update!(content: "second") }

      expect(record.created_by_id).to eq(creator.id)
    end

    it "both are nil when there is no version history" do
      record = character(content: "unsaved")

      expect(record.created_by_id).to be_nil
      expect(record.last_edited_by_id).to be_nil
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
