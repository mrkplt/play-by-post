require "rails_helper"

RSpec.describe "Draft posts", type: :system do
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

  it "prepopulates the composer with an existing draft" do
    create(:post, :draft, scene: scene, user: player, content: "My unfinished thought")

    sign_in_as(player)
    visit game_scene_path(game, scene)

    expect(find("textarea[name='post[content]']").value).to eq("My unfinished thought")
  end

  it "draft is not visible to other participants in the scene feed" do
    create(:post, :draft, scene: scene, user: player, content: "Secret draft")

    sign_in_as(gm)
    visit game_scene_path(game, scene)

    expect(page).not_to have_text("Secret draft")
  end

  it "publishes a draft when submitting the composer" do
    create(:post, :draft, scene: scene, user: player, content: "Ready to post")

    sign_in_as(player)
    visit game_scene_path(game, scene)

    click_button "Post"

    expect(page).to have_text("Ready to post")
    expect(Post.published.count).to eq(1)
    expect(Post.drafts.count).to eq(0)
  end

  it "shows draft recovery notice on a resolved scene" do
    create(:post, :draft, scene: scene, user: player, content: "Orphaned draft")
    scene.update!(resolved_at: Time.current)

    sign_in_as(player)
    visit game_scene_path(game, scene)

    expect(page).to have_text("You have an unsaved draft from this scene.")
    expect(page).to have_text("Orphaned draft")
  end

  it "discards a draft from a resolved scene" do
    create(:post, :draft, scene: scene, user: player, content: "Orphaned draft")
    scene.update!(resolved_at: Time.current)

    sign_in_as(player)
    visit game_scene_path(game, scene)

    accept_confirm { click_button "Discard Draft" }

    expect(page).not_to have_text("You have an unsaved draft from this scene.")
    expect(Post.drafts.count).to eq(0)
  end
end
