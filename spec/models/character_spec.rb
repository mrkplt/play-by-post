require "rails_helper"

RSpec.describe Character, type: :model do
  describe "validations" do
    it "requires a name" do
      expect(build(:character, name: nil)).not_to be_valid
    end

    it "is valid with required attributes" do
      expect(build(:character)).to be_valid
    end
  end

  # The snapshot's content and attribution are the logic; writing the row is the
  # after_save hook's job. Assert the attributes directly, and separately that
  # the hook is still wired to them.
  describe "#version_attributes" do
    it "captures the current content" do
      character = build_stubbed(:character, content: "Some content")
      expect(character.version_attributes[:content]).to eq("Some content")
    end

    it "renders nil content as an empty string" do
      character = build_stubbed(:character, content: nil)
      expect(character.version_attributes[:content]).to eq("")
    end

    it "records Current.user as edited_by when set" do
      editor = build_stubbed(:user)
      character = build_stubbed(:character)
      Current.user = editor
      expect(character.version_attributes[:edited_by_id]).to eq(editor.id)
    ensure
      Current.user = nil
    end

    it "falls back to the character owner when Current.user is nil" do
      Current.user = nil
      character = build_stubbed(:character)
      expect(character.version_attributes[:edited_by_id]).to eq(character.user_id)
    end
  end

  describe "version snapshot wiring" do
    it "snapshots on save" do
      character = build(:character)
      allow(character).to receive(:snapshot_version)

      character.save

      expect(character).to have_received(:snapshot_version)
    end

    it "snapshots on save!" do
      character = build(:character)
      allow(character).to receive(:snapshot_version)

      character.save!

      expect(character).to have_received(:snapshot_version)
    end

    it "does not snapshot when the save fails validation" do
      character = build(:character, name: nil)
      allow(character).to receive(:snapshot_version)

      expect(character.save).to be false
      expect(character).not_to have_received(:snapshot_version)
    end

    it "rolls back the save itself when the snapshot fails, because both share one transaction" do
      character = create(:character, content: "Original")
      allow(character).to receive(:snapshot_version).and_raise("boom")

      character.content = "Changed"
      expect { character.save }.to raise_error("boom")

      expect(character.reload.content).to eq("Original")
    end

    it "rolls back save! itself when the snapshot fails, because both share one transaction" do
      character = create(:character, content: "Original")
      allow(character).to receive(:snapshot_version).and_raise("boom")

      character.content = "Changed"
      expect { character.save! }.to raise_error("boom")

      expect(character.reload.content).to eq("Original")
    end

    it "actually creates the character_version row, unstubbed, with the current content and editor" do
      editor = create(:user, :with_profile)
      character = create(:character, content: "Some content")
      Current.user = editor

      character.update!(content: "Updated content")

      version = character.character_versions.last
      expect(version.content).to eq("Updated content")
      expect(version.edited_by).to eq(editor)
    ensure
      Current.user = nil
    end
  end

  # The branching is the logic and is now a pure decision; applying it to a
  # relation is the scope's only remaining job. No query, no rows, no SQL string
  # to match (which also makes this adapter-independent).
  describe ".visibility_rule" do
    let(:viewer) { build_stubbed(:user) }
    let(:game) { build_stubbed(:game) }

    it "gives a GM everything, whatever sheets_hidden says" do
      allow(game).to receive(:game_master?).with(viewer).and_return(true)
      allow(game).to receive(:sheets_hidden?).and_return(true)

      expect(described_class.visibility_rule(viewer, game)).to eq(:all)
    end

    it "restricts a non-GM to their own when sheets are hidden" do
      allow(game).to receive(:game_master?).with(viewer).and_return(false)
      allow(game).to receive(:sheets_hidden?).and_return(true)

      expect(described_class.visibility_rule(viewer, game)).to eq(:own_only)
    end

    it "allows unhidden plus own when sheets are not hidden" do
      allow(game).to receive(:game_master?).with(viewer).and_return(false)
      allow(game).to receive(:sheets_hidden?).and_return(false)

      expect(described_class.visibility_rule(viewer, game)).to eq(:unhidden_or_own)
    end
  end

  describe "#editable_by?" do
    let(:owner) { build_stubbed(:user) }
    let(:other) { build_stubbed(:user) }
    let(:gm_user) { build_stubbed(:user) }
    let(:game) { build_stubbed(:game) }
    let(:character) { build_stubbed(:character, game: game, user: owner) }

    it "returns true for the owner" do
      allow(game).to receive(:game_master?).with(owner).and_return(false)
      expect(character.editable_by?(owner, game)).to be true
    end

    it "returns true for the GM" do
      allow(game).to receive(:game_master?).with(gm_user).and_return(true)
      expect(character.editable_by?(gm_user, game)).to be true
    end

    it "returns false for another player" do
      allow(game).to receive(:game_master?).with(other).and_return(false)
      expect(character.editable_by?(other, game)).to be false
    end
  end
end
