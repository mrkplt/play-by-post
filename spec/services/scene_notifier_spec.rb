require "rails_helper"

RSpec.describe SceneNotifier, :db do
  let(:game) { create(:game) }
  let(:gm) { create(:user, :with_profile) }
  let(:player) { create(:user, :with_profile) }
  let(:scene) { create(:scene, game: game) }

  before do
    create(:game_member, :game_master, game: game, user: gm)
    create(:game_member, game: game, user: player)
    create(:scene_participant, scene: scene, user: gm)
    create(:scene_participant, scene: scene, user: player)
  end

  def recipients_of(mail_method)
    deliveries = []
    allow(NotificationMailer).to receive(mail_method) do |_scene, recipient|
      deliveries << recipient
      double(deliver_later: true)
    end
    yield
    deliveries
  end

  describe "#created" do
    it "notifies participants other than the actor" do
      recipients = recipients_of(:new_scene) { described_class.new(scene).created(gm) }

      expect(recipients).to contain_exactly(player)
    end

    it "does not notify the actor about their own scene" do
      recipients = recipients_of(:new_scene) { described_class.new(scene).created(gm) }

      expect(recipients).not_to include(gm)
    end

    it "skips a participant who muted the scene" do
      NotificationPreference.toggle!(scene, player)

      recipients = recipients_of(:new_scene) { described_class.new(scene).created(gm) }

      expect(recipients).to be_empty
    end
  end

  describe "#resolved" do
    it "notifies every participant, including the one who resolved it" do
      recipients = recipients_of(:scene_resolved) { described_class.new(scene).resolved }

      expect(recipients).to contain_exactly(gm, player)
    end

    it "skips a participant who muted the scene" do
      NotificationPreference.toggle!(scene, player)

      recipients = recipients_of(:scene_resolved) { described_class.new(scene).resolved }

      expect(recipients).to contain_exactly(gm)
    end
  end
end
