require "rails_helper"

RSpec.describe GamePurgeJob, type: :job do
  def stub_lookup(game)
    allow(Game).to receive(:unscoped).and_return(double(find_by: game))
  end

  describe "#perform" do
    it "destroys a soft-deleted game" do
      game = build_stubbed(:game, deleted_at: Time.current)
      stub_lookup(game)
      allow(game).to receive(:destroy!)

      described_class.new.perform(game.id)

      expect(game).to have_received(:destroy!)
    end

    it "does nothing when the game no longer exists" do
      stub_lookup(nil)
      # No game to receive :destroy! — the guard must short-circuit without error.
      expect { described_class.new.perform(123) }.not_to raise_error
    end

    it "does not destroy a game that is no longer soft-deleted" do
      game = build_stubbed(:game, deleted_at: nil)
      stub_lookup(game)
      allow(game).to receive(:destroy!)

      described_class.new.perform(game.id)

      expect(game).not_to have_received(:destroy!)
    end
  end

  describe "#perform (end to end)", db: true do
    it "removes the game, its records, and purges every attached artifact" do
      game = create(:game)
      scene = create(:scene, game: game)
      post = create(:post, scene: scene)
      post.image.attach(io: StringIO.new("img"), filename: "p.png", content_type: "image/png")
      game_file = create(:game_file, game: game)
      game_file.file.attach(io: StringIO.new("doc"), filename: "d.txt", content_type: "text/plain")
      game.soft_delete!

      expect {
        described_class.new.perform(game.id)
      }.to change { Game.unscoped.exists?(game.id) }.from(true).to(false)

      expect(Scene.exists?(scene.id)).to be(false)
      expect(Post.exists?(post.id)).to be(false)
      expect(GameFile.exists?(game_file.id)).to be(false)
      expect(ActiveStorage::Blob.where(filename: %w[p.png d.txt]).count).to eq(0)
    end
  end
end
