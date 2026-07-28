require "rails_helper"

RSpec.describe "Unread post aura", type: :feature do
  include ActionView::RecordIdentifier
  let(:gm) { create(:user) }
  let(:player) { create(:user) }
  let(:game) { create(:game) }
  let(:scene) { create(:scene, game: game) }

  before do
    create(:game_member, :game_master, game: game, user: gm)
    create(:game_member, game: game, user: player)
    create(:scene_participant, scene: scene, user: gm)
    create(:scene_participant, scene: scene, user: player)
    create(:user_profile, user: player)
  end

  it "shows gold aura on posts not yet read within 72 hours" do
    post = create(:post, scene: scene, user: gm, created_at: 1.hour.ago)

    sign_in_as(player)
    visit game_scene_path(game, scene)

    expect(page).to have_css("##{dom_id(post)}.ui-glow")
  end

  it "does not show aura on posts older than 72 hours" do
    post = create(:post, scene: scene, user: gm, created_at: 73.hours.ago)

    sign_in_as(player)
    visit game_scene_path(game, scene)

    expect(page).not_to have_css("##{dom_id(post)}.ui-glow")
  end

  it "does not show aura on already-read posts" do
    post = create(:post, scene: scene, user: gm, created_at: 1.hour.ago)
    create(:post_read, post: post, user: player)

    sign_in_as(player)
    visit game_scene_path(game, scene)

    expect(page).not_to have_css("##{dom_id(post)}.ui-glow")
  end

  it "does not show aura on posts in resolved scenes" do
    scene.update!(resolved_at: Time.current)
    post = create(:post, scene: scene, user: gm, created_at: 1.hour.ago)

    sign_in_as(player)
    visit game_scene_path(game, scene)

    expect(page).not_to have_css("##{dom_id(post)}.ui-glow")
  end
end
