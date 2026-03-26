require "rails_helper"

RSpec.describe SceneMailbox, type: :mailbox do
  include ActionMailbox::TestHelper

  let(:game) { create(:game) }
  let(:user) { create(:user, :with_profile) }
  let(:scene) { create(:scene, game: game) }

  around do |example|
    original_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test
    example.run
    ActiveJob::Base.queue_adapter = original_adapter
  end

  it "creates a post from an inbound email by a participant" do
    create(:scene_participant, scene: scene, user: user)

    expect {
      receive_inbound_email_from_mail(
        from: user.email,
        to: "scene-#{scene.id}@inbound.example.com",
        subject: "Re: Scene",
        body: "Hello from email"
      )
    }.to change { scene.posts.count }.by(1)

    expect(scene.posts.last.content).to include("Hello from email")
    expect(scene.posts.last.user).to eq(user)
  end

  it "bounces email from a non-participant" do
    non_participant = create(:user, :with_profile)

    inbound = receive_inbound_email_from_mail(
      from: non_participant.email,
      to: "scene-#{scene.id}@inbound.example.com",
      subject: "Re: Scene",
      body: "Should be bounced"
    )

    expect(inbound.bounced?).to be true
  end

  it "bounces email to an unknown scene" do
    inbound = receive_inbound_email_from_mail(
      from: user.email,
      to: "scene-999999@inbound.example.com",
      subject: "Re: Scene",
      body: "Unknown scene"
    )

    expect(inbound.bounced?).to be true
  end
end
