# frozen_string_literal: true

require "rails_helper"

RSpec.describe MailerNotifier do
  subject(:adapter) { described_class.new }

  let(:scene) { create(:scene) }
  let(:user) { create(:user) }
  let(:delivery) { instance_double(ActionMailer::MessageDelivery, deliver_later: nil) }

  describe "#notify_new_scene" do
    it "delivers a new_scene email later" do
      allow(NotificationMailer).to receive(:new_scene).with(scene, user).and_return(delivery)
      adapter.notify_new_scene(scene: scene, recipient: user)
      expect(delivery).to have_received(:deliver_later)
    end
  end

  describe "#notify_scene_resolved" do
    it "delivers a scene_resolved email later" do
      allow(NotificationMailer).to receive(:scene_resolved).with(scene, user).and_return(delivery)
      adapter.notify_scene_resolved(scene: scene, recipient: user)
      expect(delivery).to have_received(:deliver_later)
    end
  end

  describe "#notify_post_digest" do
    let(:posts) { create_list(:post, 2, scene: scene, user: user) }

    it "delivers a post_digest email later" do
      allow(NotificationMailer).to receive(:post_digest).with(scene, user, posts).and_return(delivery)
      adapter.notify_post_digest(scene: scene, user: user, posts: posts)
      expect(delivery).to have_received(:deliver_later)
    end
  end
end
