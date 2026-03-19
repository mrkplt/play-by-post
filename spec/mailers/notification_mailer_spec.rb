require "rails_helper"

RSpec.describe NotificationMailer, type: :mailer do
  describe "new_scene" do
    let(:mail) { NotificationMailer.new_scene }

    it "renders the headers" do
      expect(mail.subject).to eq("New scene")
      expect(mail.to).to eq(["to@example.org"])
      expect(mail.from).to eq(["from@example.com"])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Hi")
    end
  end

  describe "scene_resolved" do
    let(:mail) { NotificationMailer.scene_resolved }

    it "renders the headers" do
      expect(mail.subject).to eq("Scene resolved")
      expect(mail.to).to eq(["to@example.org"])
      expect(mail.from).to eq(["from@example.com"])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Hi")
    end
  end

  describe "post_digest" do
    let(:mail) { NotificationMailer.post_digest }

    it "renders the headers" do
      expect(mail.subject).to eq("Post digest")
      expect(mail.to).to eq(["to@example.org"])
      expect(mail.from).to eq(["from@example.com"])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Hi")
    end
  end

end
