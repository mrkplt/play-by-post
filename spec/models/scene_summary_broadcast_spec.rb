require "rails_helper"

# Pushes a finished summary to the per-viewer streams. Asserts WHICH streams
# receive it (the visibility classes that may see it) and that the pending frame
# and toast are both replaced — the gating that used to live in the poll
# endpoint, now enforced by which streams are broadcast to.
RSpec.describe SceneSummaryBroadcast, type: :model do
  let(:game) { create(:game) }
  let(:gm) { create(:user, :with_profile) }
  let(:scene) { create(:scene, :resolved, game: game) }

  before { create(:game_member, :game_master, game: game, user: gm) }

  def stream(klass)
    [ scene, :summary, klass ]
  end

  it "replaces the pending frame on every visibility class of a published non-AI summary" do
    summary = create(:scene_summary, scene: scene, draft: false)

    %i[manager plain hidden].each do |klass|
      captured = capture_turbo_stream_broadcasts(stream(klass)) { described_class.new(summary).call }

      expect(captured.map { |el| el["target"] }).to include(SceneSummaryChannel::PENDING_FRAME_ID)
    end
  end

  it "broadcasts an AI summary to managers and plain viewers but not hidden ones" do
    summary = create(:scene_summary, :ai_generated, scene: scene)

    captured_manager = capture_turbo_stream_broadcasts(stream(:manager)) { described_class.new(summary).call }
    captured_hidden = capture_turbo_stream_broadcasts(stream(:hidden)) { }

    expect(captured_manager).to be_present
    expect(captured_hidden).to be_empty
  end

  it "broadcasts a draft only to managers" do
    summary = create(:scene_summary, scene: scene, draft: true, body: "draft prose")

    manager = capture_turbo_stream_broadcasts(stream(:manager)) { described_class.new(summary).call }
    plain = capture_turbo_stream_broadcasts(stream(:plain)) { }

    expect(manager).to be_present
    expect(plain).to be_empty
  end

  it "targets the pending frame and the toast layer" do
    summary = create(:scene_summary, scene: scene, draft: false)

    elements = capture_turbo_stream_broadcasts(stream(:plain)) { described_class.new(summary).call }
    targets = elements.map { |el| el["target"] }

    expect(targets).to include(SceneSummaryChannel::PENDING_FRAME_ID, "toast_layer")
  end

  it "renders the manage affordances only in the manager stream" do
    summary = create(:scene_summary, scene: scene, draft: false)

    manager = capture_turbo_stream_broadcasts(stream(:manager)) { described_class.new(summary).call }
    plain = capture_turbo_stream_broadcasts(stream(:plain)) { described_class.new(summary).call }

    expect(manager.map(&:to_html).join).to include("Edit")
    expect(plain.map(&:to_html).join).not_to include("Edit")
  end
end
