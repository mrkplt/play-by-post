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

  it "creates the post with is_ooc set to false" do
    create(:scene_participant, scene: scene, user: user)

    receive_inbound_email_from_mail(
      from: user.email,
      to: "scene-#{scene.id}@inbound.example.com",
      subject: "Re: Scene",
      body: "An in-character action"
    )

    expect(scene.posts.last.is_ooc).to be false
  end

  it "passes the email body through EmailContentExtractor and saves the extracted content" do
    create(:scene_participant, scene: scene, user: user)
    allow_any_instance_of(EmailContentExtractor).to receive(:extract).and_return("Extracted reply text")

    receive_inbound_email_from_mail(
      from: user.email,
      to: "scene-#{scene.id}@inbound.example.com",
      subject: "Re: Scene",
      body: "Extracted reply text\n\n> Previous message that should be stripped"
    )

    expect(scene.posts.last.content).to eq("Extracted reply text")
  end

  it "creates the post from the full raw body when the email extractor falls back" do
    create(:scene_participant, scene: scene, user: user)
    body_with_quoted_text = "My reply here\n\n> Quoted content that would normally be stripped"

    # In the test environment no OpenRouter API key is configured, so EmailContentExtractor
    # returns the raw body unchanged. Verify the post preserves the complete raw body.
    receive_inbound_email_from_mail(
      from: user.email,
      to: "scene-#{scene.id}@inbound.example.com",
      subject: "Re: Scene",
      body: body_with_quoted_text
    )

    expect(scene.posts.last.content).to include("> Quoted content that would normally be stripped")
  end
end
