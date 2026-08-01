require "rails_helper"

RSpec.describe User, type: :model do
  describe "#display_name" do
    it "returns display_name from user_profile when profile exists" do
      user = create(:user, :with_profile)
      expect(user.display_name).to eq(user.user_profile.display_name)
    end

    it "returns nil when no profile exists" do
      user = create(:user)
      expect(user.display_name).to be_nil
    end
  end

  describe "associations" do
    it "has many game_members" do
      expect(User.reflect_on_association(:game_members).macro).to eq(:has_many)
    end

    it "has many games through game_members" do
      association = User.reflect_on_association(:games)

      expect(association.macro).to eq(:has_many)
      expect(association.options[:through]).to eq(:game_members)
    end
  end

  describe "#send_devise_notification" do
    it "delivers the magic link off the request cycle, not inline" do
      user = build_stubbed(:user)
      message = double(deliver_later: true, deliver_now: true)
      allow(user).to receive(:devise_mailer).and_return(double(send: message))

      user.send_devise_notification(:magic_link, "token", false)

      expect(message).to have_received(:deliver_later)
      expect(message).not_to have_received(:deliver_now)
    end
  end
end
