require "rails_helper"

RSpec.describe NotificationMailer, type: :mailer do
  let(:game) { create(:game) }
  let(:scene) { create(:scene, game: game, title: "The Dark Forest") }
  let(:recipient) { create(:user, :with_profile) }

  describe "new_scene" do
    let(:mail) { NotificationMailer.new_scene(scene, recipient) }

    it "renders the headers" do
      expect(mail.subject).to include(game.name)
      expect(mail.subject).to include(scene.title)
      expect(mail.to).to eq([ recipient.email ])
    end

    it "sets a scene reply-to address" do
      expect(mail.reply_to.first).to match(/scene-#{scene.id}@/)
    end

    it "uses resend_inbound_domain credential as the reply-to domain when configured" do
      allow(Rails.application.credentials).to receive(:resend_inbound_domain).and_return("reply.example.com")
      expect(NotificationMailer.new_scene(scene, recipient).reply_to.first).to eq("scene-#{scene.id}@reply.example.com")
    end

    it "falls back to the mailer host when resend_inbound_domain is not set" do
      allow(Rails.application.credentials).to receive(:resend_inbound_domain).and_return(nil)
      expect(mail.reply_to.first).to match(/@example\.com\z/)
    end

    it "renders the body with a link" do
      expect(mail.body.encoded).to include("scene")
    end
  end

  describe "scene_resolved" do
    let(:mail) { NotificationMailer.scene_resolved(scene, recipient) }

    it "renders the headers" do
      expect(mail.subject).to include(game.name)
      expect(mail.subject).to include(scene.title)
      expect(mail.to).to eq([ recipient.email ])
    end

    it "renders the body" do
      expect(mail.body.encoded).to include("scene")
    end
  end

  describe "post_digest" do
    let(:posts) { create_list(:post, 3, scene: scene) }
    let(:mail) { NotificationMailer.post_digest(scene, recipient, posts) }

    it "renders the headers" do
      expect(mail.subject).to include(game.name)
      expect(mail.subject).to include(scene.title)
      expect(mail.to).to eq([ recipient.email ])
    end

    it "sets a scene reply-to address" do
      expect(mail.reply_to.first).to match(/scene-#{scene.id}@/)
    end

    it "renders the body with post content" do
      expect(mail.body.encoded).to include("scene")
    end
  end
end
