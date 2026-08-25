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

  describe "#export_all_games_notice", :db do
    it "renders a 'Last export: X ago' notice when a valid all-games receipt exists" do
      user = create(:user)
      receipt = create(:game_export_request, :all_games, user: user, succeeded_at: 3.hours.ago)
      receipt.archive.attach(io: StringIO.new("zip"), filename: "all.zip", content_type: "application/zip")

      expect(described_class.new(user).export_all_games_notice).to match(/\ALast export: .+ ago\z/)
    end

    it "returns generic delivery-window copy when no receipt is present" do
      user = create(:user)
      expect(described_class.new(user).export_all_games_notice)
        .to eq("You'll receive an email with a download link within a few minutes; the link expires after 7 days.")
    end
  end

  describe "#game_control_rows", db: true do
    let(:user) { create(:user) }
    let(:helpers) { double("helpers") }

    it "returns one row per non-banned membership, pairing tokens by scope" do
      with_feed = create(:game, name: "With Feed")
      without_feed = create(:game, name: "Without Feed")
      create(:game_member, game: with_feed, user: user)
      create(:game_member, game: without_feed, user: user)
      create(:api_token, user: user, game: with_feed, scope: "rss")
      create(:api_token, user: user, game: without_feed, scope: "api")

      rows = described_class.new(user, helpers: helpers).game_control_rows

      expect(rows.size).to eq(2)
      expect(rows).to all(be_a(GameControlRowPresenter))
      feed_row = rows.find { |r| r.name == "With Feed" }
      api_row = rows.find { |r| r.name == "Without Feed" }
      expect(feed_row.feed.token?).to be(true)
      expect(feed_row.api.token?).to be(false)
      expect(api_row.feed.token?).to be(false)
      expect(api_row.api.token?).to be(true)
    end

    it "excludes banned memberships" do
      banned = create(:game, name: "Forbidden Keep")
      create(:game_member, :banned, game: banned, user: user)

      rows = described_class.new(user, helpers: helpers).game_control_rows

      expect(rows.map(&:name)).not_to include("Forbidden Keep")
    end

    it "marks a game's contributed features on the funding cells" do
      allow_any_instance_of(User).to receive(:ai_key_present?).and_return(true)
      funded = create(:game, name: "Funded")
      create(:game_member, game: funded, user: user)
      create(:game_key_authorization, game: funded, user: user, feature: "scene_summary")

      allow(helpers).to receive(:game_key_contributions_path).and_return("/create")
      allow(helpers).to receive(:game_key_contribution_path).and_return("/destroy")

      rows = described_class.new(user, helpers: helpers).game_control_rows

      expect(rows.first.ai_cells.first).to be_a(KeyContributionRowPresenter::Offered)
    end
  end

  describe "#byok_key" do
    it "returns a UserByokKeyPresenter for the model" do
      expect(presenter.byok_key).to be_a(UserByokKeyPresenter)
    end

    it "memoizes across calls" do
      expect(presenter.byok_key).to equal(presenter.byok_key)
    end
  end

  describe "avatar library", :db do
    let(:user) { create(:user) }
    let(:helpers) do
      double("helpers").tap do |h|
        allow(h).to receive(:url_for) { |variant| "/blob/#{variant.object_id}" }
        allow(h).to receive(:profile_images_path).and_return("/profile/images")
        allow(h).to receive(:profile_image_path) { |image| "/profile/images/#{image.id}" }
      end
    end

    subject(:presenter) { described_class.new(user, helpers: helpers) }

    it "#avatar is the user's avatar library presenter, built with the injected helpers" do
      expect(presenter.avatar).to be_a(UserAvatarLibraryPresenter)
    end

    it "#avatar exposes the library items" do
      create(:user_image, :with_file, :current, user: user)
      expect(presenter.avatar.items.map { |i| i[:current] }).to eq([ true ])
    end

    it "#avatar exposes the upload url and the current avatar url" do
      create(:user_image, :with_file, :current, user: user)
      expect(presenter.avatar.upload_url).to eq("/profile/images")
      expect(presenter.avatar.current_url).to match(%r{\A/blob/})
    end

    it "memoizes the avatar presenter" do
      expect(presenter.avatar).to be(presenter.avatar)
    end
  end
end
