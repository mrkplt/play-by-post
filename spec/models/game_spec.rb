require "rails_helper"

RSpec.describe Game, type: :model do
  describe "validations" do
    it "requires a name" do
      game = build(:game, name: nil)
      expect(game).not_to be_valid
      expect(game.errors[:name]).to be_present
    end

    it "enforces max name length of 200" do
      game = build(:game, name: "a" * 201)
      expect(game).not_to be_valid
    end

    it "is valid with a name" do
      expect(build(:game)).to be_valid
    end
  end

  describe "#game_master?" do
    let(:game) { create(:game) }
    let(:gm_user) { create(:user) }
    let(:player_user) { create(:user) }

    before do
      create(:game_member, :game_master, game: game, user: gm_user)
      create(:game_member, game: game, user: player_user)
    end

    it "returns true for the GM" do
      members = double
      allow(members).to receive(:exists?).with(user: gm_user, role: "game_master").and_return(true)
      allow(game).to receive(:game_members).and_return(members)

      expect(game.game_master?(gm_user)).to be true
    end

    it "returns false for a player" do
      members = double
      allow(members).to receive(:exists?).with(user: player_user, role: "game_master").and_return(false)
      allow(game).to receive(:game_members).and_return(members)

      expect(game.game_master?(player_user)).to be false
    end
  end

  describe "soft deletion" do
    describe "default scope" do
      it "hides soft-deleted games" do
        expect(unquoted_sql(Game.all)).to include("games.deleted_at IS NULL")
      end
    end

    describe "#soft_delete!" do
      it "stamps deleted_at with the current time" do
        game = build_stubbed(:game)
        allow(game).to receive(:update!)

        Timecop.freeze do
          game.soft_delete!
          expect(game).to have_received(:update!).with(deleted_at: Time.current)
        end
      end
    end

    describe "#deleted?" do
      it "is true once deleted_at is set" do
        expect(build_stubbed(:game, deleted_at: Time.current).deleted?).to be(true)
      end

      it "is false while deleted_at is nil" do
        expect(build_stubbed(:game, deleted_at: nil).deleted?).to be(false)
      end
    end

    describe "export requests" do
      it "are destroyed with the game so none dangle against a purged game" do
        expect(Game.reflect_on_association(:game_export_requests).options[:dependent]).to eq(:destroy)
      end
    end
  end

  describe "#edit_window_duration" do
    it "returns nil when post_edit_window_minutes is nil" do
      expect(build(:game, post_edit_window_minutes: nil).edit_window_duration).to be_nil
    end

    it "returns an ActiveSupport::Duration matching the minutes" do
      expect(build(:game, post_edit_window_minutes: 60).edit_window_duration).to eq(60.minutes)
    end
  end

  describe "#active_member?" do
    let(:game) { create(:game) }
    let(:user) { create(:user) }

    it "returns true for active members" do
      members = double
      allow(members).to receive(:exists?).with(user: user, status: "active").and_return(true)
      allow(game).to receive(:game_members).and_return(members)

      expect(game.active_member?(user)).to be true
    end

    it "returns false for removed members" do
      members = double
      allow(members).to receive(:exists?).with(user: user, status: "active").and_return(false)
      allow(game).to receive(:game_members).and_return(members)

      expect(game.active_member?(user)).to be false
    end
  end

  describe "#viewable_by?" do
    let(:game) { build_stubbed(:game) }
    let(:user) { build_stubbed(:user) }

    # Each predicate is isolated so a mutation dropping one term from the
    # game_master? || active? || removed? chain flips the result.
    def stub_membership(member)
      allow(game).to receive(:member_for).with(user).and_return(member)
    end

    it "returns false when the user is not a member" do
      stub_membership(nil)
      expect(game.viewable_by?(user)).to be false
    end

    it "returns true for the game master, by role and independent of status" do
      stub_membership(instance_double(GameMember, game_master?: true, active?: false, removed?: false))
      expect(game.viewable_by?(user)).to be true
    end

    it "returns true for an active member" do
      stub_membership(instance_double(GameMember, game_master?: false, active?: true, removed?: false))
      expect(game.viewable_by?(user)).to be true
    end

    it "returns true for a removed member" do
      stub_membership(instance_double(GameMember, game_master?: false, active?: false, removed?: true))
      expect(game.viewable_by?(user)).to be true
    end

    it "returns false for a member who is neither GM, active, nor removed (banned)" do
      stub_membership(instance_double(GameMember, game_master?: false, active?: false, removed?: false))
      expect(game.viewable_by?(user)).to be false
    end
  end
end
