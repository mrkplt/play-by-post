require "rails_helper"

RSpec.describe GameDashboardQuery, :db do
  let(:viewer) { create(:user, :with_profile) }
  let(:policies) { ->(record) { GamePolicy.new(viewer, record) } }

  def query
    described_class.new(viewer, policies)
  end

  describe "#memberships" do
    it "includes an active membership" do
      game = create(:game, name: "Alpha")
      create(:game_member, game: game, user: viewer, status: "active")

      expect(query.memberships.map(&:game_id)).to eq([ game.id ])
    end

    it "includes a removed member so they keep their history" do
      game = create(:game, name: "Alpha")
      create(:game_member, :removed, game: game, user: viewer)

      expect(query.memberships.map(&:game_id)).to eq([ game.id ])
    end

    it "excludes a banned member" do
      game = create(:game)
      create(:game_member, game: game, user: viewer, status: "banned")

      expect(query.memberships).to be_empty
    end

    it "excludes a membership whose game was soft-deleted" do
      game = create(:game)
      create(:game_member, game: game, user: viewer, status: "active")
      game.soft_delete!

      expect(query.memberships).to be_empty
    end

    it "orders by game name" do
      first = create(:game, name: "Beta")
      second = create(:game, name: "Alpha")
      create(:game_member, game: first, user: viewer, status: "active")
      create(:game_member, game: second, user: viewer, status: "active")

      expect(query.memberships.map { |m| T.must(m.game).name }).to eq([ "Alpha", "Beta" ])
    end
  end

  describe "#policy_by_game_id" do
    it "resolves a policy per game through the injected callable" do
      game = create(:game)
      create(:game_member, game: game, user: viewer, status: "active")

      expect(query.policy_by_game_id[game.id]).to be_a(GamePolicy)
    end

    # A soft-deleted game reads as nil through the default scope. #memberships
    # already filters those out, so this only fires if a game is deleted
    # between the two reads — but it is the guard that stops a nil reaching
    # the presenter.
    it "skips a membership whose game has gone" do
      game = create(:game)
      create(:game_member, game: game, user: viewer, status: "active")
      built = query
      built.memberships.each { |membership| allow(membership).to receive(:game).and_return(nil) }

      expect(built.policy_by_game_id).to be_empty
    end
  end

  describe "#games_with_new_activity" do
    it "is empty when the viewer has never logged in" do
      game = create(:game)
      create(:game_member, game: game, user: viewer, status: "active")
      viewer.user_profile.update!(last_login_at: nil)

      expect(query.games_with_new_activity).to be_empty
    end

    it "is empty when the viewer has no profile at all" do
      game = create(:game)
      create(:game_member, game: game, user: viewer, status: "active")
      viewer.user_profile.destroy
      viewer.reload

      expect(query.games_with_new_activity).to be_empty
    end

    it "is empty when the viewer has no memberships" do
      viewer.user_profile.update!(last_login_at: 1.day.ago)

      expect(query.games_with_new_activity).to be_empty
    end

    it "lists a game with a post newer than the last login" do
      game = create(:game)
      create(:game_member, game: game, user: viewer, status: "active")
      scene = create(:scene, game: game)
      viewer.user_profile.update!(last_login_at: 2.days.ago)
      create(:post, scene: scene, user: viewer, created_at: 1.hour.ago)

      expect(query.games_with_new_activity).to eq([ game.id ])
    end

    it "ignores a game whose posts all predate the last login" do
      game = create(:game)
      create(:game_member, game: game, user: viewer, status: "active")
      scene = create(:scene, game: game)
      create(:post, scene: scene, user: viewer, created_at: 3.days.ago)
      viewer.user_profile.update!(last_login_at: 1.day.ago)

      expect(query.games_with_new_activity).to be_empty
    end
  end

  describe "#presenter" do
    it "builds a dashboard presenter over the memberships" do
      game = create(:game)
      create(:game_member, game: game, user: viewer, status: "active")

      expect(query.presenter).to be_a(GameDashboardPresenter)
    end
  end
end
