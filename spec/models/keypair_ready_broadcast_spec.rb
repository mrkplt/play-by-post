require "rails_helper"

# Pushes the finished keypair to the owner's Profile screen. Asserts the pending
# frame is replaced with the paste form and a "ready" toast is dropped, both on
# the owner's own keypair stream.
RSpec.describe KeypairReadyBroadcast, type: :model do
  let(:owner) { create(:user, :with_profile) }
  let(:encrypted_value) { create(:encrypted_value, owner: owner) }

  def stream
    [ owner, :byok_keypair ]
  end

  it "replaces the pending frame and the toast layer on the owner's stream", :db do
    captured = capture_turbo_stream_broadcasts(stream) { described_class.new(encrypted_value).call }

    targets = captured.map { |el| el["target"] }
    expect(targets).to include(ByokKeyChannel::PENDING_FRAME_ID, "toast_layer")
  end

  it "renders the paste-and-seal form into the pending frame", :db do
    captured = capture_turbo_stream_broadcasts(stream) { described_class.new(encrypted_value).call }

    frame_swap = captured.find { |el| el["target"] == ByokKeyChannel::PENDING_FRAME_ID }
    expect(frame_swap.to_html).to include("byok-key-seal")
  end

  it "carries the freshly generated public key PEM the browser encrypts to", :db do
    captured = capture_turbo_stream_broadcasts(stream) { described_class.new(encrypted_value).call }

    frame_swap = captured.find { |el| el["target"] == ByokKeyChannel::PENDING_FRAME_ID }
    expect(frame_swap.to_html).to include(T.must(encrypted_value.public_key).public_key)
  end

  it "drops a ready toast", :db do
    captured = capture_turbo_stream_broadcasts(stream) { described_class.new(encrypted_value).call }

    toast_swap = captured.find { |el| el["target"] == "toast_layer" }
    expect(toast_swap.to_html).to include("Your encryption key is ready.")
  end

  it "does not broadcast to a different user's stream", :db do
    other = create(:user, :with_profile)

    captured = capture_turbo_stream_broadcasts([ other, :byok_keypair ]) do
      described_class.new(encrypted_value).call
    end

    expect(captured).to be_empty
  end
end
