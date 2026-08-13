require "rails_helper"

RSpec.describe ApiTokenPolicy, type: :policy do
  subject(:policy) { described_class.new(token.user, token) }

  let(:game) { create(:game) }
  let(:user) { create(:user, :with_profile) }
  let(:token) { create(:api_token, user: user, game: game, scope: scope) }
  let(:scope) { "rss" }

  describe "#feed?" do
    context "with an rss token whose user is an active member", :db do
      before { create(:game_member, game: game, user: user) }

      it "permits" do
        expect(policy.feed?).to be(true)
      end
    end

    context "with an rss token whose user is the GM", :db do
      before { create(:game_member, :game_master, game: game, user: user) }

      it "permits" do
        expect(policy.feed?).to be(true)
      end
    end

    context "with an rss token whose user was removed", :db do
      before { create(:game_member, :removed, game: game, user: user) }

      it "denies" do
        expect(policy.feed?).to be(false)
      end
    end

    context "with an rss token whose user is not a member", :db do
      it "denies" do
        expect(policy.feed?).to be(false)
      end
    end

    context "with a non-rss scope even for an active member", :db do
      let(:scope) { "api" }
      before { create(:game_member, game: game, user: user) }

      it "denies" do
        expect(policy.feed?).to be(false)
      end
    end
  end
end
