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

  describe "#authenticatable_salt" do
    it "returns the remember_token so the session has a real, per-user salt" do
      user = build_stubbed(:user, remember_token: "salt-value")
      expect(user.authenticatable_salt).to eq("salt-value")
    end

    it "is generated on create so it is never nil for a persisted user", :db do
      user = create(:user)
      expect(user.authenticatable_salt).to be_present
    end

    it "lets the session reject a stale salt (revocation)", :db do
      user = create(:user)
      key = User.serialize_into_session(user)

      expect(User.serialize_from_session(*key)&.id).to eq(user.id)
      expect(User.serialize_from_session(key[0], "stale-salt")).to be_nil
    end
  end

  describe "remember_token generation" do
    it "assigns a random, distinct token to each user on create", :db do
      a = create(:user)
      b = create(:user)

      expect(a.remember_token).to be_present
      expect(a.remember_token).not_to eq(b.remember_token)
    end

    it "does not overwrite an explicitly provided token", :db do
      user = create(:user, remember_token: "chosen")
      expect(user.remember_token).to eq("chosen")
    end
  end

  describe "#after_magic_link_authentication" do
    it "regenerates a token cleared by sign-out so the salt stays present", :db do
      user = create(:user)
      user.update_column(:remember_token, nil)

      expect { user.after_magic_link_authentication }
        .to change { user.reload.remember_token }.from(nil).to(be_present)
    end

    it "leaves an existing token untouched", :db do
      user = create(:user)
      original = user.remember_token

      user.after_magic_link_authentication

      expect(user.reload.remember_token).to eq(original)
    end
  end

  describe "#send_devise_notification" do
    it "delivers the magic link off the request cycle, not inline" do
      user = build_stubbed(:user)
      # A real ActionMailer::MessageDelivery (dispatch is by class, not
      # respond_to?, so a plain double would not exercise the branch).
      message = ActionMailer::MessageDelivery.new(ApplicationMailer, :welcome_email)
      allow(message).to receive(:deliver_later)
      allow(message).to receive(:deliver_now)
      mailer = double
      allow(mailer).to receive(:send).and_return(message)
      allow(user).to receive(:devise_mailer).and_return(mailer)

      user.send_devise_notification(:magic_link, "token", false)

      expect(mailer).to have_received(:send).with(:magic_link, user, "token", false)
      expect(message).to have_received(:deliver_later)
      expect(message).not_to have_received(:deliver_now)
    end

    it "delivers now when the message is not an ActionMailer::MessageDelivery" do
      user = build_stubbed(:user)
      # Devise::Mailer can hand back a raw Mail::Message for some notification
      # paths (no deliver_later), so anything other than a MessageDelivery
      # must fall through to deliver_now. A plain object (not a double, since
      # dispatch is now by class/is_a?, which a double never satisfies) stands
      # in for that raw-message shape.
      message = Object.new
      def message.deliver_now; end
      allow(message).to receive(:deliver_now)
      allow(user).to receive(:devise_mailer).and_return(double(send: message))

      user.send_devise_notification(:magic_link, "token")

      expect(message).to have_received(:deliver_now)
    end
  end

  describe "#current_avatar", :db do
    it "is the user's current library image" do
      user = create(:user)
      create(:user_image, user: user)
      current = create(:user_image, :current, user: user)

      expect(user.current_avatar).to eq(current)
    end

    it "is nil when no image is current" do
      user = create(:user)
      create(:user_image, user: user)

      expect(user.current_avatar).to be_nil
    end
  end

  describe "#avatar_variant", :db do
    it "is the display variant of the current avatar" do
      user = create(:user)
      create(:user_image, :current, :with_file, user: user)

      expect(user.avatar_variant).to be_a(ActiveStorage::VariantWithRecord)
    end

    it "is nil when there is no current avatar" do
      user = create(:user)

      expect(user.avatar_variant).to be_nil
    end
  end

  describe "#ai_key_present?" do
    it "is true when the user's openrouter_key EncryptedValue has a sealed value", db: true do
      user = create(:user)
      create(:encrypted_value, :sealed, owner: user, value_type: "openrouter_key")

      expect(user.ai_key_present?).to be(true)
    end

    it "is false when no EncryptedValue exists for this user", db: true do
      user = create(:user)
      expect(user.ai_key_present?).to be(false)
    end

    it "is false when the EncryptedValue exists but has no sealed value yet (keypair generated, nothing pasted)", db: true do
      user = create(:user)
      create(:encrypted_value, owner: user, value_type: "openrouter_key", sealed_value: nil)

      expect(user.ai_key_present?).to be(false)
    end

    it "is false when the user has a sealed EncryptedValue of a different value_type", db: true do
      user = create(:user)
      create(:encrypted_value, :sealed, owner: user, value_type: "something_else")

      expect(user.ai_key_present?).to be(false)
    end
  end
end
