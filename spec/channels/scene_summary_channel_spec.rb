require "rails_helper"

# Subscription authorization: a viewer may subscribe only to the summary stream
# for their OWN visibility class on a game they can see. The signed stream name
# stops a client inventing a stream; this channel additionally rejects a valid
# signed name for a class the viewer is not entitled to.
RSpec.describe SceneSummaryChannel, type: :channel do
  let(:game) { create(:game) }
  let(:gm) { create(:user, :with_profile) }
  let(:player) { create(:user, :with_profile) }
  let(:scene) { create(:scene, :resolved, game: game) }

  before do
    create(:game_member, :game_master, game: game, user: gm)
    create(:game_member, game: game, user: player)
  end

  def signed(klass)
    Turbo::StreamsChannel.signed_stream_name([ scene, :summary, klass ])
  end

  def subscribe_to(klass, scene_id: scene.id)
    subscribe(signed_stream_name: signed(klass), scene_id: scene_id)
  end

  it "accepts a manager subscribing to the manager stream" do
    stub_connection(current_user: gm)
    subscribe_to(:manager)

    expect(subscription).to be_confirmed
    # Streams from the verified (unsigned) name, the same form broadcasts target.
    expect(subscription).to have_stream_from(Turbo::StreamsChannel.verified_stream_name(signed(:manager)))
  end

  it "accepts a plain player subscribing to the plain stream" do
    stub_connection(current_user: player)
    subscribe_to(:plain)

    expect(subscription).to be_confirmed
  end

  it "rejects a plain player who replays the manager stream name" do
    stub_connection(current_user: player)
    subscribe_to(:manager)

    expect(subscription).to be_rejected
  end

  it "rejects a hidden-preference player subscribing to the plain stream" do
    player.user_profile.update!(ai_display_preference: :hidden)
    stub_connection(current_user: player)
    subscribe_to(:plain)

    expect(subscription).to be_rejected
  end

  it "rejects a non-member of the game" do
    outsider = create(:user, :with_profile)
    stub_connection(current_user: outsider)
    subscribe_to(:plain)

    expect(subscription).to be_rejected
  end

  it "rejects when the scene does not exist" do
    stub_connection(current_user: gm)
    subscribe_to(:manager, scene_id: 0)

    expect(subscription).to be_rejected
  end
end
