require "rails_helper"

# Subscription authorization: a viewer may subscribe to a scene's post stream
# only when they can view the scene (game access plus the private-scene gate).
# The signed stream name stops a client inventing a stream; this channel
# additionally rejects a valid signed name for a scene the viewer cannot see.
RSpec.describe PostsChannel, type: :channel do
  let(:game) { create(:game) }
  let(:gm) { create(:user, :with_profile) }
  let(:player) { create(:user, :with_profile) }
  let(:scene) { create(:scene, game: game) }

  before do
    create(:game_member, :game_master, game: game, user: gm)
    create(:game_member, game: game, user: player)
  end

  def signed(target_scene = scene)
    Turbo::StreamsChannel.signed_stream_name([ target_scene, :posts ])
  end

  def subscribe_to(signed_name: signed, scene_id: scene.id)
    subscribe(signed_stream_name: signed_name, scene_id: scene_id)
  end

  it "accepts a member subscribing to a public scene's post stream" do
    stub_connection(current_user: player)
    subscribe_to

    expect(subscription).to be_confirmed
    # Streams from the verified (unsigned) name, the same form broadcasts target.
    expect(subscription).to have_stream_from(Turbo::StreamsChannel.verified_stream_name(signed))
  end

  it "accepts the GM subscribing to the post stream" do
    stub_connection(current_user: gm)
    subscribe_to

    expect(subscription).to be_confirmed
  end

  it "rejects a non-member of the game" do
    outsider = create(:user, :with_profile)
    stub_connection(current_user: outsider)
    subscribe_to

    expect(subscription).to be_rejected
  end

  it "rejects a member who is not a participant of a private scene" do
    private_scene = create(:scene, game: game, private: true)
    stub_connection(current_user: player)
    subscribe_to(signed_name: signed(private_scene), scene_id: private_scene.id)

    expect(subscription).to be_rejected
  end

  it "accepts a participant of a private scene" do
    private_scene = create(:scene, game: game, private: true)
    create(:scene_participant, scene: private_scene, user: player)
    stub_connection(current_user: player)
    subscribe_to(signed_name: signed(private_scene), scene_id: private_scene.id)

    expect(subscription).to be_confirmed
  end

  it "rejects a signed name for one scene replayed against another scene_id" do
    other_scene = create(:scene, game: game)
    stub_connection(current_user: player)
    subscribe_to(signed_name: signed(other_scene), scene_id: scene.id)

    expect(subscription).to be_rejected
  end

  it "rejects when the scene does not exist" do
    stub_connection(current_user: player)
    subscribe_to(scene_id: 0)

    expect(subscription).to be_rejected
  end
end
