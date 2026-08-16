require "rails_helper"

RSpec.describe Invitation, type: :model do
  describe "validations" do
    it "requires an email" do
      expect(build(:invitation, email: nil)).not_to be_valid
    end

    it "requires a valid email format" do
      expect(build(:invitation, email: "notanemail")).not_to be_valid
    end

    it "is valid with required attributes" do
      expect(build(:invitation)).to be_valid
    end
  end

  describe "token generation" do
    it "generates a token before validation" do
      invitation = build(:invitation, token: nil)
      invitation.valid?
      expect(invitation.token).to be_present
    end

    it "does not overwrite an existing token" do
      invitation = build(:invitation, token: "custom-token")
      invitation.valid?
      expect(invitation.token).to eq("custom-token")
    end
  end

  describe "#accept!" do
    it "stamps accepted_at with the current time" do
      invitation = build(:invitation)
      expect(invitation.accepted_at).to be_nil

      Timecop.freeze do
        invitation.accept!
        # be_within, not eq: on the real adapter accept! round-trips through
        # SQLite, which truncates the nanoseconds Time.current carries.
        expect(invitation.accepted_at).to be_within(1.second).of(Time.current)
      end
    end

    it "writes the change rather than only assigning it" do
      invitation = build(:invitation)
      allow(invitation).to receive(:update!)

      invitation.accept!

      expect(invitation).to have_received(:update!).with(hash_including(:accepted_at))
    end

    it "makes the invitation accepted" do
      invitation = create(:invitation)
      invitation.accept!
      expect(invitation.accepted?).to be true
    end
  end

  describe "#generate_token" do
    it "generates a URL-safe base64 token" do
      invitation = build(:invitation, token: nil)
      invitation.valid?
      expect(invitation.token).to match(/\A[A-Za-z0-9_-]+\z/)
    end

    it "generates tokens of sufficient length" do
      invitation = build(:invitation, token: nil)
      invitation.valid?
      expect(invitation.token.length).to be >= 32
    end
  end

  describe "#accepted?" do
    it "returns false when not accepted" do
      expect(build(:invitation).accepted?).to be false
    end

    it "returns true when accepted" do
      expect(build(:invitation, :accepted).accepted?).to be true
    end
  end

  describe "#accept_for!" do
    it "creates an active player membership for the user in the invitation's game" do
      game = create(:game)
      invitation = create(:invitation, game: game)
      user = create(:user)

      invitation.accept_for!(user)

      membership = game.game_members.find_by(user: user)
      expect(membership).to be_present
      expect(membership.role).to eq("player")
      expect(membership.status).to eq("active")
    end

    it "marks the invitation accepted" do
      invitation = create(:invitation)
      user = create(:user)

      invitation.accept_for!(user)

      expect(invitation.accepted?).to be true
    end

    it "does not duplicate an existing membership for the user" do
      game = create(:game)
      invitation = create(:invitation, game: game)
      user = create(:user)
      game.game_members.create!(user: user, role: "player", status: "active")

      expect {
        invitation.accept_for!(user)
      }.not_to change(GameMember, :count)
    end
  end
end
