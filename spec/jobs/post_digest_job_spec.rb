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

  # The per-participant decision is pure; the surrounding loop only feeds it.
  describe "#notify?" do
    let(:scene) { build_stubbed(:scene) }
    let(:user) { build_stubbed(:user) }

    def decide(last_visited_at:, muted: false)
      allow(NotificationPreference).to receive(:muted?).with(scene, user).and_return(muted)
      participant = build_stubbed(:scene_participant, last_visited_at: last_visited_at)
      described_class.new.notify?(scene, user, participant)
    end

    it "notifies a participant who has never visited" do
      expect(decide(last_visited_at: nil)).to be true
    end

    it "notifies a participant away longer than the window" do
      expect(decide(last_visited_at: 2.days.ago)).to be true
    end

    it "skips a participant who visited inside the window" do
      expect(decide(last_visited_at: 1.hour.ago)).to be false
    end

    # Not the exact boundary: assigning it round-trips through attribute casting,
    # which truncates sub-second precision and flips the comparison.
    it "skips a participant just inside the window" do
      Timecop.freeze do
        expect(decide(last_visited_at: described_class::WINDOW.ago + 1.second)).to be false
      end
    end

    it "notifies a participant just outside the window" do
      Timecop.freeze do
        expect(decide(last_visited_at: described_class::WINDOW.ago - 1.second)).to be true
      end
    end

    it "skips a muted participant who would otherwise qualify" do
      expect(decide(last_visited_at: 2.days.ago, muted: true)).to be false
    end
  end
end
