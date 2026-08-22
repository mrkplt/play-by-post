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
      it "cascade on destroy, matching the other game associations" do
        reflection = Game.reflect_on_association(:game_export_requests)
        expect(reflection).to be_present
        expect(reflection.options[:dependent]).to eq(:destroy)
      end
    end
  end

  # The slug is assigned in-band on save (create path), not in a callback.
  describe "slug assignment on save", db: true do
    it "assigns a name-derived slug with a random suffix and persists via save!" do
      game = build(:game, name: "Dragons of Icespire Peak", slug: nil)
      game.save!
      expect(game).to be_persisted
      expect(game.reload.slug).to match(/\Adragons-of-icespire-peak-[a-z0-9]{6}\z/)
    end

    it "assigns the slug and persists through the non-bang save path too" do
      game = build(:game, name: "Dragons of Icespire Peak", slug: nil)
      expect(game.save).to be(true)
      expect(game.reload.slug).to match(/\Adragons-of-icespire-peak-[a-z0-9]{6}\z/)
    end

    it "does not overwrite a slug supplied at build time" do
      game = build(:game, slug: "existing-slug-abc123")
      game.save!
      expect(game.slug).to eq("existing-slug-abc123")
    end

    it "leaves a renamed game's slug untouched, so its URL stays stable" do
      game = create(:game, name: "Original Name", slug: nil)
      original = game.slug
      game.update!(name: "Renamed Game")
      expect(game.reload.slug).to eq(original)
    end

    # Forwards save options to super: an over-length name fails the model's
    # length validation but is DB-valid, so validate: false persists it — which
    # only holds if **options reaches ActiveRecord#save rather than super().
    it "forwards save options through to ActiveRecord (save)" do
      game = build(:game, name: "a" * 201, slug: "long-name-slug-abc123")
      expect(game.save(validate: false)).to be(true)
      expect(game).to be_persisted
    end

    it "forwards save options through to ActiveRecord (save!)" do
      game = build(:game, name: "a" * 201, slug: "long-name-slug-def456")
      game.save!(validate: false)
      expect(game).to be_persisted
    end
  end

  describe "#to_param" do
    it "routes by slug, not id" do
      game = build(:game, slug: "a-game-abc123")
      expect(game.to_param).to eq("a-game-abc123")
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

    def stub_membership(member)
      allow(game).to receive(:member_for).with(user).and_return(member)
    end

    it "returns false when the user is not a member" do
      stub_membership(nil)
      expect(game.viewable_by?(user)).to be false
    end

    it "delegates to the membership's own #viewable? when a member" do
      stub_membership(instance_double(GameMember, viewable?: true))
      expect(game.viewable_by?(user)).to be true

      stub_membership(instance_double(GameMember, viewable?: false))
      expect(game.viewable_by?(user)).to be false
    end
  end
end
