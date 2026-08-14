require "rails_helper"

RSpec.describe ScenePresenter do
  let(:scene) { build(:scene, created_at: Time.zone.parse("2024-03-10 09:00:00")) }

  subject(:presenter) { described_class.new(scene) }

  describe "#model" do
    it "returns the wrapped scene" do
      expect(presenter.model).to eq(scene)
    end
  end

  describe "#hot?" do
    it "is false when the id is not among the supplied hot_scene_ids" do
      scene.id = 5
      expect(described_class.new(scene, hot_scene_ids: Set.new([ 1, 2 ])).hot?).to be(false)
    end

    it "is true when the id is among the supplied hot_scene_ids" do
      scene.id = 5
      expect(described_class.new(scene, hot_scene_ids: Set.new([ 5 ])).hot?).to be(true)
    end

    it "is false when no hot_scene_ids were supplied" do
      expect(presenter.hot?).to be(false)
    end
  end

  describe "#save_draft_url" do
    let(:game) { build_stubbed(:game) }
    let(:urls) { double(save_draft_game_scene_posts_path: "/games/1/scenes/2/posts/save_draft") }

    subject(:presenter) { described_class.new(scene, game: game, urls: urls) }

    it "resolves the save-draft URL against its own game and scene" do
      expect(presenter.save_draft_url).to eq("/games/1/scenes/2/posts/save_draft")
      expect(urls).to have_received(:save_draft_game_scene_posts_path).with(game, scene)
    end
  end

  describe "#discard_draft_url" do
    let(:game) { build_stubbed(:game) }
    let(:urls) { double(discard_draft_game_scene_posts_path: "/games/1/scenes/2/posts/discard_draft") }

    subject(:presenter) { described_class.new(scene, game: game, urls: urls) }

    it "resolves the discard-draft URL against its own game and scene" do
      expect(presenter.discard_draft_url).to eq("/games/1/scenes/2/posts/discard_draft")
      expect(urls).to have_received(:discard_draft_game_scene_posts_path).with(game, scene)
    end
  end

  describe "#errors?" do
    it "is false on a clean scene" do
      expect(presenter.errors?).to be(false)
    end

    it "is true once the scene carries a validation error" do
      scene.errors.add(:base, "Something went wrong")
      expect(presenter.errors?).to be(true)
    end
  end

  describe "#error_messages" do
    it "is empty on a clean scene" do
      expect(presenter.error_messages).to be_empty
    end

    it "surfaces the scene's full error messages" do
      scene.errors.add(:base, "Something went wrong")
      expect(presenter.error_messages).to include("Something went wrong")
    end
  end

  describe "#parent_option_label" do
    context "when active" do
      it { expect(presenter.parent_option_label).to eq(scene.title) }
    end

    context "when resolved" do
      let(:scene) { build(:scene, :resolved) }

      it { expect(presenter.parent_option_label).to eq("#{scene.title} (Resolved)") }
    end
  end

  describe "#status_label" do
    context "when active" do
      it { expect(presenter.status_label).to eq("Active") }
    end

    context "when resolved" do
      let(:scene) { build(:scene, :resolved) }

      it { expect(presenter.status_label).to eq("Resolved") }
    end
  end

  describe "#status_badges" do
    it "is empty for an ordinary public active scene" do
      expect(presenter.status_badges).to eq([])
    end

    it "includes only Resolved for a resolved public scene" do
      scene = build(:scene, :resolved)
      expect(described_class.new(scene).status_badges).to eq([ { label: "Resolved", variant: :gray } ])
    end

    it "includes only Private for a private active scene" do
      scene = build(:scene, :private)
      expect(described_class.new(scene).status_badges).to eq([ { label: "Private", variant: :yellow } ])
    end

    it "includes both Private and Resolved, in that order, for a private resolved scene" do
      scene = build(:scene, :private, :resolved)
      expect(described_class.new(scene).status_badges).to eq([
        { label: "Private", variant: :yellow },
        { label: "Resolved", variant: :gray }
      ])
    end
  end

  describe "#formatted_created_at" do
    it "formats the timestamp" do
      expect(presenter.formatted_created_at).to eq("Mar 10, 2024  9:00am")
    end
  end

  describe "#participant_names" do
    it "returns empty string when there are no participants" do
      allow(scene).to receive(:scene_participants).and_return(
        double(includes: [])
      )
      expect(presenter.participant_names).to eq("")
    end

    it "includes participants without characters (e.g. GM)" do
      sp = double(display_name: "Alice")
      allow(scene).to receive(:scene_participants).and_return(
        double(includes: [ sp ])
      )
      expect(presenter.participant_names).to eq("Alice")
    end

    it "joins multiple participants with a comma" do
      sp1 = double(display_name: "Alice")
      sp2 = double(display_name: "Bob")
      allow(scene).to receive(:scene_participants).and_return(
        double(includes: [ sp1, sp2 ])
      )
      expect(presenter.participant_names).to eq("Alice, Bob")
    end
  end

  describe "#banner_image" do
    it "returns a variant with correct transformations" do
      scene = build(:scene)
      scene.image.attach(io: File.open(Rails.root.join("spec/fixtures/files/test_image.png")),
                         filename: "banner.png", content_type: "image/png")
      result = described_class.new(scene).banner_image
      expect(result).to be_a(ActiveStorage::VariantWithRecord)
      expect(result.variation.transformations).to eq(
        resize_to_limit: [ 1200, nil ], format: :jpeg, quality: 85
      )
    end
  end

  describe "#participant_summary" do
    # Only the count reaches the pluralisation, so stub the association the way
    # #participant_names above already does rather than inserting participants.
    def summary_for(count)
      allow(scene).to receive(:scene_participants).and_return(double(count: count))
      presenter.participant_summary
    end

    it "pluralizes for zero participants" do
      expect(summary_for(0)).to eq("0 participants")
    end

    it "singularizes for one participant" do
      expect(summary_for(1)).to eq("1 participant")
    end

    it "pluralizes for several participants" do
      expect(summary_for(2)).to eq("2 participants")
    end
  end

  describe "#resolution" do
    it "returns the model's resolution" do
      allow(scene).to receive(:resolution).and_return("The dragon fell.")
      expect(presenter.resolution).to eq("The dragon fell.")
    end

    it "returns nil when there is no resolution" do
      allow(scene).to receive(:resolution).and_return(nil)
      expect(presenter.resolution).to be_nil
    end
  end

  describe "#resolve_path" do
    it "builds the scene's resolve path from the injected game and url_helpers" do
      game = build_stubbed(:game)
      urls = double("urls")
      allow(urls).to receive(:resolve_game_scene_path).with(game, scene).and_return("/games/1/scenes/2/resolve")

      presenter = described_class.new(scene, game: game, urls: urls)
      expect(presenter.resolve_path).to eq("/games/1/scenes/2/resolve")
    end
  end

  describe "delegation" do
    it "delegates resolved? to the model" do
      allow(scene).to receive(:resolved?).and_return(true)
      expect(presenter.resolved?).to be true
    end

    it "delegates private? to the model" do
      allow(scene).to receive(:private?).and_return(true)
      expect(presenter.private?).to be true
    end

    it "delegates title to the model" do
      expect(presenter.title).to eq(scene.title)
    end
  end
end
