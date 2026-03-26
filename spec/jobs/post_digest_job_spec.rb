require "rails_helper"

RSpec.describe PostDigestJob, type: :job do
  let(:game) { create(:game) }
  let(:gm) { create(:user, :with_profile) }
  let(:player) { create(:user, :with_profile) }
  let(:scene) { create(:scene, game: game) }

  before do
    create(:game_member, :game_master, game: game, user: gm)
    create(:game_member, game: game, user: player)
  end

  around do |example|
    original_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test
    example.run
    ActiveJob::Base.queue_adapter = original_adapter
  end

  it "sends digest to participant who hasn't visited in 24+ hours with recent posts from others" do
    create(:scene_participant, scene: scene, user: gm, last_visited_at: 2.days.ago)
    create(:scene_participant, scene: scene, user: player)
    create(:post, scene: scene, user: player, content: "New activity")

    PostDigestJob.perform_now

    expect(ActiveJob::Base.queue_adapter.enqueued_jobs.any? { |j|
      j["job_class"] == "ActionMailer::MailDeliveryJob" &&
      j["arguments"]&.first == "NotificationMailer" &&
      j["arguments"]&.second == "post_digest"
    }).to be true
  end

  it "does not send to muted participant" do
    create(:scene_participant, scene: scene, user: gm, last_visited_at: 2.days.ago)
    create(:scene_participant, scene: scene, user: player)
    create(:post, scene: scene, user: player, content: "New activity")
    create(:notification_preference, scene: scene, user: gm, muted: true)

    PostDigestJob.perform_now

    expect(ActiveJob::Base.queue_adapter.enqueued_jobs.select { |j|
      j["job_class"] == "ActionMailer::MailDeliveryJob" &&
      j["arguments"]&.first == "NotificationMailer" &&
      j["arguments"]&.second == "post_digest"
    }).to be_empty
  end

  it "does not send to participant who visited recently" do
    create(:scene_participant, scene: scene, user: gm, last_visited_at: 30.minutes.ago)
    create(:scene_participant, scene: scene, user: player)
    create(:post, scene: scene, user: player, content: "New activity")

    PostDigestJob.perform_now

    expect(ActiveJob::Base.queue_adapter.enqueued_jobs.select { |j|
      j["job_class"] == "ActionMailer::MailDeliveryJob" &&
      j["arguments"]&.first == "NotificationMailer" &&
      j["arguments"]&.second == "post_digest"
    }).to be_empty
  end

  it "does not send when participant authored the only recent post" do
    create(:scene_participant, scene: scene, user: player, last_visited_at: 2.days.ago)
    create(:post, scene: scene, user: player, content: "My own post")

    PostDigestJob.perform_now

    expect(ActiveJob::Base.queue_adapter.enqueued_jobs.select { |j|
      j["job_class"] == "ActionMailer::MailDeliveryJob" &&
      j["arguments"]&.first == "NotificationMailer" &&
      j["arguments"]&.second == "post_digest"
    }).to be_empty
  end
end
