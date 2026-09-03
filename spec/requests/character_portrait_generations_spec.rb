require "rails_helper"

RSpec.describe CharacterPortraitGenerationsController, type: :request do
  let(:gm) { create(:user, :with_profile) }
  let(:player) { create(:user, :with_profile) }
  let(:other) { create(:user, :with_profile) }
  let(:game) { create(:game) }
  let(:character) { create(:character, game: game, user: player) }

  before do
    create(:game_member, :game_master, game: game, user: gm)
    create(:game_member, game: game, user: player)
    create(:game_member, game: game, user: other)
  end

  def generation_path
    game_character_portrait_generation_path(game, character)
  end

  # The portrait-poll Stimulus controller fetches with this Accept header.
  TURBO_HEADERS = { "Accept" => "text/vnd.turbo-stream.html" }.freeze

  describe "POST (create)" do
    around do |example|
      original = ActiveJob::Base.queue_adapter
      ActiveJob::Base.queue_adapter = :test
      example.run
      ActiveJob::Base.queue_adapter = original
    end

    it "creates a pending skeleton, enqueues the job, and renders the pending control" do
      sign_in(player)

      expect {
        post generation_path, params: { portrait: { prompt: "a dwarven smith" } }
      }.to change { character.character_images.pending.count }.by(1)
        .and have_enqueued_job(CharacterPortraitJob)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("character_portrait_generator")
    end

    it "rejects a blank prompt without enqueuing or creating a skeleton" do
      sign_in(player)

      expect {
        post generation_path, params: { portrait: { prompt: "  " } }
      }.to change { character.character_images.count }.by(0)
        .and have_enqueued_job(CharacterPortraitJob).exactly(0).times

      expect(response.body).to include("Please describe your character")
    end

    it "denies a non-owner (GM included)" do
      sign_in(gm)

      post generation_path, params: { portrait: { prompt: "x" } }

      expect(response).to have_http_status(:forbidden).or have_http_status(:redirect)
      expect(character.character_images.count).to eq(0)
    end
  end

  describe "GET (show — poll target)" do
    it "renders the pending control while a skeleton is still pending" do
      character.character_images.create!
      sign_in(player)

      get generation_path, headers: TURBO_HEADERS

      expect(response.body).to include("character_portrait_generator")
      expect(response.body).to include("portrait-poll")
    end

    it "refreshes the library and drops a success toast once settled (nothing pending)" do
      create(:character_image, :with_file, character: character)
      sign_in(player)

      get generation_path, headers: TURBO_HEADERS

      expect(response.body).to include("image_library_character_image")
      expect(response.body).to include("Portrait generated")
      expect(response.body).not_to include("portrait-poll")
    end

    it "surfaces a failure reason and cleans up the dead skeleton" do
      skeleton = character.character_images.create!
      skeleton.fail_generation!("That prompt was blocked by content moderation.")
      sign_in(player)

      get generation_path, headers: TURBO_HEADERS

      expect(response.body).to include("blocked by content moderation")
      expect(CharacterImage.exists?(skeleton.id)).to be(false)
    end
  end
end
