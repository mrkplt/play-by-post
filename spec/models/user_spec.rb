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
    it "has many game_members", db: true do

      user = create(:user)
      game = create(:game)
      member = create(:game_member, user: user, game: game)
      expect(user.game_members).to include(member)
    end

    it "has many games through game_members", db: true do

      user = create(:user)
      game = create(:game)
      create(:game_member, user: user, game: game)
      expect(user.games).to include(game)
    end
  end

  describe "#send_devise_notification" do
    around do |example|
      original_adapter = ActiveJob::Base.queue_adapter
      ActiveJob::Base.queue_adapter = :test
      example.run
      ActiveJob::Base.queue_adapter = original_adapter
    end

    it "enqueues the magic link email via Active Job (worker), not inline", db: true do

      user = create(:user, :with_profile)

      expect {
        user.send_devise_notification(:magic_link, "token", false)
      }.to have_enqueued_job(ActionMailer::MailDeliveryJob)
    end

    it "does not deliver the magic link synchronously" do
      user = create(:user, :with_profile)

      # deliver_later enqueues rather than sending in-process; with the :test
      # queue adapter no delivery happens until the job is performed.
      expect {
        user.send_devise_notification(:magic_link, "token", false)
      }.not_to change { ActionMailer::Base.deliveries.size }
    end

    it "builds the requested notification from the devise mailer with the user and args" do
      user = create(:user, :with_profile)
      message = instance_double(ActionMailer::MessageDelivery, deliver_later: nil)
      mailer = double("devise_mailer")
      allow(user).to receive(:devise_mailer).and_return(mailer)
      expect(mailer).to receive(:magic_link).with(user, "token", true).and_return(message)

      user.send_devise_notification(:magic_link, "token", true)

      expect(message).to have_received(:deliver_later)
    end

    it "delivers now when the message cannot be delivered later" do
      user = create(:user, :with_profile)
      message = double("message")
      allow(message).to receive(:respond_to?).with(:deliver_later).and_return(false)
      mailer = double("devise_mailer", magic_link: message)
      allow(user).to receive(:devise_mailer).and_return(mailer)

      expect(message).to receive(:deliver_now)
      expect(message).not_to receive(:deliver_later)

      user.send_devise_notification(:magic_link, "token", false)
    end
  end
end
