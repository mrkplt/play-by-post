require "rails_helper"

RSpec.describe SceneResolution, :db do
  let(:game) { create(:game) }
  let(:scene) { create(:scene, game: game) }

  around do |example|
    adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test
    example.run
  ensure
    ActiveJob::Base.queue_adapter = adapter
  end

  it "stamps the resolution and the time it happened" do
    Timecop.freeze(Time.utc(2026, 6, 15, 9, 30)) do
      described_class.new(scene).call("They escaped.")
    end

    expect(scene.reload.resolution).to eq("They escaped.")
    expect(scene.resolved_at).to eq(Time.utc(2026, 6, 15, 9, 30))
  end

  it "reports success when the scene was open" do
    expect(described_class.new(scene).call("Done.")).to be(true)
  end

  it "notifies participants" do
    notifier = instance_double(SceneNotifier, resolved: nil)
    allow(SceneNotifier).to receive(:new).with(scene).and_return(notifier)

    described_class.new(scene).call("Done.")

    expect(notifier).to have_received(:resolved)
  end

  it "queues a summary when the game has AI summaries enabled" do
    game.update!(ai_summaries_enabled: true)

    expect { described_class.new(scene).call("Done.") }
      .to have_enqueued_job(SceneSummaryJob).with(scene.id)
  end

  it "does not queue a summary when the game has them disabled" do
    game.update!(ai_summaries_enabled: false)

    expect { described_class.new(scene).call("Done.") }.not_to have_enqueued_job(SceneSummaryJob)
  end

  context "when the scene is already resolved" do
    let(:scene) { create(:scene, :resolved, game: game) }

    it "reports failure rather than resolving twice" do
      expect(described_class.new(scene).call("Again.")).to be(false)
    end

    it "leaves the existing resolution untouched" do
      expect { described_class.new(scene).call("Again.") }.not_to change { scene.reload.resolution }
    end

    it "does not notify anyone" do
      allow(SceneNotifier).to receive(:new)

      described_class.new(scene).call("Again.")

      expect(SceneNotifier).not_to have_received(:new)
    end
  end
end
