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

  # The extracted reads still need covering — stubbing them in the specs above
  # means nothing executes their query, so every mutation of it would survive.
  describe "reads" do
    let(:job) { described_class.new }

    describe "#active_scenes" do
      it "selects unresolved scenes with a post inside the window" do
        Timecop.freeze do
          sql = unquoted_sql(job.active_scenes)

          expect(sql).to include("scenes.resolved_at IS NULL")
          expect(sql).to include("INNER JOIN posts")
          expect(sql).to include("posts.created_at >=")
          expect(sql).to include("DISTINCT")
        end
      end
    end

    describe "#participants_for" do
      it "eager loads each participant's user" do
        scene = build_stubbed(:scene)
        participants = double
        allow(scene).to receive(:scene_participants).and_return(participants)
        allow(participants).to receive(:includes).and_return(participants)

        job.participants_for(scene)

        expect(participants).to have_received(:includes).with(:user)
      end
    end

    describe "#posts_since_visit" do
      let(:scene) { build_stubbed(:scene) }
      let(:user) { build_stubbed(:user) }
      let(:relation) { double }

      before do
        allow(scene).to receive(:posts).and_return(relation)
        allow(relation).to receive(:where).and_return(relation)
        allow(relation).to receive(:not).and_return(relation)
        allow(relation).to receive(:order).and_return(relation)
        allow(relation).to receive(:to_a).and_return([])
      end

      it "takes posts made after the last visit" do
        last_visit = 3.hours.ago

        job.posts_since_visit(scene, user, last_visit)

        expect(relation).to have_received(:where).with("created_at > ?", last_visit)
      end

      it "falls back to the window when there is no last visit" do
        Timecop.freeze do
          job.posts_since_visit(scene, user, nil)

          expect(relation).to have_received(:where).with("created_at > ?", described_class::WINDOW.ago)
        end
      end

      it "excludes the recipient's own posts, oldest first" do
        job.posts_since_visit(scene, user, 1.hour.ago)

        expect(relation).to have_received(:not).with(user: user)
        expect(relation).to have_received(:order).with(:created_at)
      end
    end
  end

  describe "#perform" do
    let(:job) { described_class.new }
    let(:scene) { build_stubbed(:scene) }
    let(:recipient) { build_stubbed(:user) }
    let(:participant) { build_stubbed(:scene_participant, user: recipient) }
    let(:post) { build_stubbed(:post) }
    let(:mail) { double(deliver_later: true) }

    before do
      allow(job).to receive(:active_scenes).and_return([ scene ])
      allow(job).to receive(:participants_for).with(scene).and_return([ participant ])
      allow(job).to receive(:notify?).and_return(true)
      allow(job).to receive(:posts_since_visit).and_return([ post ])
      allow(NotificationMailer).to receive(:post_digest).and_return(mail)
    end

    it "mails each owed participant their unseen posts" do
      job.perform

      expect(NotificationMailer).to have_received(:post_digest).with(scene, recipient, [ post ])
      expect(mail).to have_received(:deliver_later)
    end

    it "skips a participant the rule excludes" do
      allow(job).to receive(:notify?).and_return(false)

      job.perform

      expect(NotificationMailer).not_to have_received(:post_digest)
    end

    it "skips a participant with nothing new to read" do
      allow(job).to receive(:posts_since_visit).and_return([])

      job.perform

      expect(NotificationMailer).not_to have_received(:post_digest)
    end

    it "skips a participant with no user" do
      allow(participant).to receive(:user).and_return(nil)

      job.perform

      expect(NotificationMailer).not_to have_received(:post_digest)
    end

    it "asks the rule about that scene, user and participant" do
      job.perform

      expect(job).to have_received(:notify?).with(scene, recipient, participant)
    end
  end
end
