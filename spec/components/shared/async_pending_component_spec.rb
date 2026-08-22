require "rails_helper"

RSpec.describe Shared::AsyncPendingComponent, type: :component do
  def pending(**overrides)
    described_class.new(frame_id: "thing_pending", stream: "things_1", **overrides)
  end

  it "renders a turbo-frame and a cable stream source subscribed to the stream" do
    render_inline(pending)

    expect(page).to have_css("turbo-frame#thing_pending")
    expect(page).to have_css("turbo-cable-stream-source[signed-stream-name]")
  end

  it "subscribes through the given channel and passes its data params" do
    render_inline(pending(channel: "SceneSummaryChannel", stream_data: { scene_id: 7 }))

    expect(page).to have_css("turbo-cable-stream-source[channel='SceneSummaryChannel'][data-scene-id='7']")
  end

  it "subscribes to a composite streamable when given an array" do
    scene = create(:scene)
    render_inline(described_class.new(frame_id: "thing_pending", stream: [ scene, :summary, :plain ]))

    expected = Turbo::StreamsChannel.signed_stream_name([ scene, :summary, :plain ])
    expect(page).to have_css("turbo-cable-stream-source[signed-stream-name='#{expected}']")
  end

  it "does not carry an eager src (the frame waits for a broadcast)" do
    render_inline(pending)

    expect(page).not_to have_css("turbo-frame#thing_pending[src]")
  end

  it "shows a spinner and the waiting message" do
    render_inline(pending(message: "Working on it…"))

    expect(page).to have_text("Working on it…")
    expect(page).to have_css("turbo-frame#thing_pending span[role='status']")
  end

  it "defaults the waiting message" do
    render_inline(pending)

    expect(page).to have_text("Waiting…")
  end
end
