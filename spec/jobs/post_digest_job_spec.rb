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
    post = create(:post, scene: scene, user: player, content: "New activity")

    PostDigestJob.perform_now

    digest_jobs = ActiveJob::Base.queue_adapter.enqueued_jobs.select { |j|
      j["job_class"] == "ActionMailer::MailDeliveryJob" &&
      j["arguments"]&.first == "NotificationMailer" &&
      j["arguments"]&.second == "post_digest"
    }
    expect(digest_jobs.size).to eq(1)

    args = digest_jobs.first["arguments"]
    params = args[3]["args"]
    expect(params[0]["_aj_globalid"]).to include("Scene/#{scene.id}")
    expect(params[1]["_aj_globalid"]).to include("User/#{gm.id}")
    expect(params[2].size).to eq(1)
    expect(params[2].first["_aj_globalid"]).to include("Post/#{post.id}")
  end

  it "does not send to muted participant but still sends to others" do
    third_player = create(:user, :with_profile)
    create(:game_member, game: game, user: third_player)
    create(:scene_participant, scene: scene, user: gm, last_visited_at: 2.days.ago)
    create(:scene_participant, scene: scene, user: third_player, last_visited_at: 2.days.ago)
    create(:scene_participant, scene: scene, user: player)
    create(:post, scene: scene, user: player, content: "New activity")
    create(:notification_preference, scene: scene, user: gm, muted: true)

    PostDigestJob.perform_now

    digest_jobs = ActiveJob::Base.queue_adapter.enqueued_jobs.select { |j|
      j["job_class"] == "ActionMailer::MailDeliveryJob" &&
      j["arguments"]&.first == "NotificationMailer" &&
      j["arguments"]&.second == "post_digest"
    }
    expect(digest_jobs.size).to eq(1)
    args = digest_jobs.first["arguments"]
    expect(args[3]["args"][1]["_aj_globalid"]).to include("User/#{third_player.id}")
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

  it "does not send to participant who visited exactly 23.5 hours ago" do
    create(:scene_participant, scene: scene, user: gm, last_visited_at: 23.5.hours.ago)
    create(:scene_participant, scene: scene, user: player)
    create(:post, scene: scene, user: player, content: "New activity")

    PostDigestJob.perform_now

    expect(ActiveJob::Base.queue_adapter.enqueued_jobs.select { |j|
      j["job_class"] == "ActionMailer::MailDeliveryJob" &&
      j["arguments"]&.first == "NotificationMailer" &&
      j["arguments"]&.second == "post_digest"
    }).to be_empty
  end

  it "sends digest to participant who has never visited (nil last_visited_at)" do
    create(:scene_participant, scene: scene, user: gm, last_visited_at: nil)
    create(:scene_participant, scene: scene, user: player)
    create(:post, scene: scene, user: player, content: "New activity")

    PostDigestJob.perform_now

    digest_jobs = ActiveJob::Base.queue_adapter.enqueued_jobs.select { |j|
      j["job_class"] == "ActionMailer::MailDeliveryJob" &&
      j["arguments"]&.first == "NotificationMailer" &&
      j["arguments"]&.second == "post_digest"
    }
    expect(digest_jobs.size).to eq(1)
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
