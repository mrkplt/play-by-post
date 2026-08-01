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

  # #process is the mailbox's own work: extract the body, then write the post.
  # Driving it directly keeps the write out of the assertion — the routing
  # callbacks that need ActionMailbox are covered separately below.
  describe "#process" do
    let(:participant) { build_stubbed(:user) }
    let(:target_scene) { build_stubbed(:scene) }
    let(:posts) { double }

    def process_with(body)
      mailbox = described_class.new(double(mail: nil))
      allow(mailbox).to receive(:mail).and_return(double(decoded: body))
      allow(mailbox).to receive(:scene).and_return(target_scene)
      allow(mailbox).to receive(:sender_user).and_return(participant)
      allow(target_scene).to receive(:posts).and_return(posts)
      allow(posts).to receive(:create!)
      mailbox.process
      mailbox
    end

    it "writes the extracted content as an in-character post by the sender" do
      allow_any_instance_of(EmailContentExtractor).to receive(:extract).and_return("Hello from email")

      process_with("Hello from email\n\n> quoted")

      expect(posts).to have_received(:create!)
        .with(user: participant, content: "Hello from email", is_ooc: false)
    end

    it "passes the raw body through the extractor" do
      extractor = instance_double(EmailContentExtractor, extract: "Extracted reply text")
      allow(EmailContentExtractor).to receive(:new).with("Raw body").and_return(extractor)

      process_with("Raw body")

      expect(posts).to have_received(:create!).with(hash_including(content: "Extracted reply text"))
    end

    it "writes nothing when the extracted content is blank" do
      allow_any_instance_of(EmailContentExtractor).to receive(:extract).and_return("   ")

      process_with("   ")

      expect(posts).not_to have_received(:create!)
    end
  end

  # The routing callbacks do need ActionMailbox: they read the envelope and
  # bounce, which is the part with no meaningful stub.
  describe "routing", db: true do
    it "delivers a participant's mail to the scene named in the address" do
      create(:scene_participant, scene: scene, user: user)

      expect {
        receive_inbound_email_from_mail(
          from: user.email,
          to: "scene-#{scene.id}@inbound.example.com",
          subject: "Re: Scene",
          body: "Hello from email"
        )
      }.to change { scene.posts.count }.by(1)
    end
  end
end
