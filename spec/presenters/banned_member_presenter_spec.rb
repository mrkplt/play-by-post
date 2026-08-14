require "rails_helper"

RSpec.describe BannedMemberPresenter do
  let(:user) { build_stubbed(:user) }
  let(:member) { build_stubbed(:game_member, user: user, status: "banned") }

  subject(:presenter) { described_class.new(member) }

  describe "#member" do
    it "returns the wrapped membership" do
      expect(presenter.member).to eq(member)
    end
  end

  describe "#display_name" do
    it "delegates to UserPresenter for the member's display name" do
      allow(user).to receive(:display_name).and_return("Bob")
      expect(presenter.display_name).to eq("Bob")
    end
  end
end
