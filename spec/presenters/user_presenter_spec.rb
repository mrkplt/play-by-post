require "rails_helper"

RSpec.describe UserPresenter do
  let(:user) { build_stubbed(:user, email: "jane@example.com") }

  subject(:presenter) { described_class.new(user) }

  describe "#display_name_or_email" do
    context "when the user has a display name" do
      before { allow(user).to receive(:display_name).and_return("Lady Ashford") }

      it { expect(presenter.display_name_or_email).to eq("Lady Ashford") }
    end

    context "when the user has no display name" do
      before { allow(user).to receive(:display_name).and_return(nil) }

      it "returns the email prefix" do
        expect(presenter.display_name_or_email).to eq("jane")
      end
    end
  end

  # The query is ours; executing it is ActiveRecord's. Assert the construction.
  describe "#games_by_recent_activity" do
    subject(:presenter) { described_class.new(build_stubbed(:user)) }

    it "orders by latest scene activity, falling back to when the game was made" do
      expect(unquoted_sql(presenter.games_by_recent_activity))
        .to include("ORDER BY COALESCE(MAX(scenes.updated_at), games.created_at) DESC")
    end

    it "excludes removed and banned memberships" do
      sql = unquoted_sql(presenter.games_by_recent_activity)

      expect(sql).to include("removed")
      expect(sql).to include("banned")
    end

    it "left joins scenes so games without any still appear" do
      expect(unquoted_sql(presenter.games_by_recent_activity)).to include("LEFT OUTER JOIN scenes")
    end

    it "groups by game so MAX collapses per game" do
      expect(unquoted_sql(presenter.games_by_recent_activity)).to include("GROUP BY games.id")
    end

    it "applies a limit when given one" do
      expect(unquoted_sql(presenter.games_by_recent_activity(limit: 3))).to include("LIMIT 3")
    end

    it "applies no limit otherwise" do
      expect(unquoted_sql(presenter.games_by_recent_activity)).not_to include("LIMIT")
    end
  end

  describe "delegation" do
    it "delegates email to the model" do
      expect(presenter.email).to eq("jane@example.com")
    end
  end

  # where.not is the only database part; the ordering is a Ruby sort_by.
  describe "#drawer_memberships" do
    subject(:presenter) { described_class.new(user_with_memberships) }

    let(:user_with_memberships) { build_stubbed(:user) }
    let(:relation) { double }

    def membership(game_name)
      build_stubbed(:game_member, game: build_stubbed(:game, name: game_name))
    end

    before do
      allow(relation).to receive(:where).and_return(relation)
      allow(relation).to receive(:not).and_return(relation)
      allow(relation).to receive(:includes).and_return(
        [ membership("Charlie"), membership("Alpha"), membership("Beta") ]
      )
      allow(user_with_memberships).to receive(:game_members).and_return(relation)
    end

    it "orders memberships by game name" do
      expect(presenter.drawer_memberships.map { |m| m.game.name }).to eq(%w[Alpha Beta Charlie])
    end

    it "excludes banned memberships" do
      presenter.drawer_memberships

      expect(relation).to have_received(:not).with(status: "banned")
    end

    it "returns GameMember records" do
      expect(presenter.drawer_memberships).to all(be_a(GameMember))
    end

    context "with a soft-deleted game", db: true do
      it "drops memberships whose game was soft-deleted" do
        user = create(:user)
        live = create(:game, name: "Live One")
        gone = create(:game, name: "Gone One")
        create(:game_member, game: live, user: user)
        create(:game_member, game: gone, user: user)
        gone.soft_delete!

        names = described_class.new(user).drawer_memberships.map { |m| m.game.name }
        expect(names).to eq([ "Live One" ])
      end
    end
  end

  describe "#rss_scopes", db: true do
    let(:user) { create(:user) }
    let(:game_a) { create(:game, name: "Alpha") }
    let(:game_b) { create(:game, name: "Beta") }

    before do
      create(:game_member, game: game_a, user: user)
      create(:game_member, game: game_b, user: user)
    end

    it "leads with an account-level scope" do
      scope = described_class.new(user).rss_scopes.first

      expect(scope.label).to eq("All games")
      expect(scope.game).to be_nil
    end

    it "adds one scope per non-banned game, ordered by name" do
      scopes = described_class.new(user).rss_scopes

      expect(scopes.map(&:label)).to eq([ "All games", "Alpha", "Beta" ])
      expect(scopes[1].game).to eq(game_a)
    end

    it "pairs each scope with its existing token" do
      account_token = create(:rss_token, user: user, game: nil)
      game_token = create(:rss_token, user: user, game: game_a)

      scopes = described_class.new(user).rss_scopes

      expect(scopes[0].token).to eq(account_token)
      expect(scopes[1].token).to eq(game_token)
      expect(scopes[2].token).to be_nil
    end

    it "marks only the final scope as last" do
      scopes = described_class.new(user).rss_scopes

      expect(scopes.map(&:last)).to eq([ false, false, true ])
    end
  end
end
