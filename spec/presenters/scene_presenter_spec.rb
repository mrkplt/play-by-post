require "rails_helper"

RSpec.describe ScenePresenter do
  let(:scene) { build(:scene, created_at: Time.zone.parse("2024-03-10 09:00:00")) }

  subject(:presenter) { described_class.new(scene) }

  describe "#can_post?" do
    it "is true when the post policy allows it and the scene is open" do
      post_policy = instance_double(PostPolicy, create?: true)
      presenter = described_class.new(scene, post_policy: post_policy)
      allow(scene).to receive(:resolved?).and_return(false)
      expect(presenter.can_post?).to be(true)
    end

    it "is false when the scene is resolved" do
      post_policy = instance_double(PostPolicy, create?: true)
      presenter = described_class.new(scene, post_policy: post_policy)
      allow(scene).to receive(:resolved?).and_return(true)
      expect(presenter.can_post?).to be(false)
    end

    it "is false when the post policy denies it" do
      post_policy = instance_double(PostPolicy, create?: false)
      presenter = described_class.new(scene, post_policy: post_policy)
      allow(scene).to receive(:resolved?).and_return(false)
      expect(presenter.can_post?).to be(false)
    end
  end

  describe "#mute_toggle_label" do
    it "returns Unmute notifications when muted" do
      expect(presenter.mute_toggle_label(true)).to eq("Unmute notifications")
    end

    it "returns Mute notifications when not muted" do
      expect(presenter.mute_toggle_label(false)).to eq("Mute notifications")
    end
  end

  describe "#recoverable_draft" do
    let(:draft) { build_stubbed(:post, :draft, scene: scene) }

    it "wraps the draft in a PostPresenter when the scene is resolved" do
      allow(scene).to receive(:resolved?).and_return(true)
      result = presenter.recoverable_draft(draft)
      expect(result).to be_a(PostPresenter)
      expect(result.__getobj__).to eq(draft)
    end

    it "is nil when the scene is not resolved, even with a draft present" do
      allow(scene).to receive(:resolved?).and_return(false)
      expect(presenter.recoverable_draft(draft)).to be_nil
    end

    it "is nil when there is no draft, even on a resolved scene" do
      allow(scene).to receive(:resolved?).and_return(true)
      expect(presenter.recoverable_draft(nil)).to be_nil
    end
  end

  describe "#page_action" do
    let(:game) { build_stubbed(:game) }
    let(:membership) { build_stubbed(:game_member) }
    let(:urls) { double(join_game_scene_participants_path: "/games/1/scenes/2/participants/join") }

    subject(:presenter) { described_class.new(scene, game: game, urls: urls) }

    def page_action(**overrides)
      presenter.page_action(
        **{ can_manage: false, is_participant: false, membership: membership }.merge(overrides)
      )
    end

    it "wraps the viewer facts and its own scene when asking for the action" do
      allow(ScenePageAction).to receive(:for).and_return(ScenePageAction::JOIN)

      page_action

      expect(ScenePageAction).to have_received(:for) do |scene:, viewer:|
        expect(scene).to eq(self.scene)
        expect(viewer).to have_attributes(
          can_manage: false, is_participant: false, membership: membership
        )
      end
    end

    it "resolves the action's route against the caller's url helpers" do
      allow(ScenePageAction).to receive(:for).and_return(ScenePageAction::JOIN)

      expect(page_action).to have_attributes(
        label: "Join Scene",
        href: "/games/1/scenes/2/participants/join",
        http_method: :post
      )
      expect(urls).to have_received(:join_game_scene_participants_path).with(game, scene)
    end

    it "is nil when there is no action, without touching the url helpers" do
      allow(ScenePageAction).to receive(:for).and_return(nil)

      expect(page_action).to be_nil
      expect(urls).not_to have_received(:join_game_scene_participants_path)
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

  describe "#tree_status_badges" do
    it "always includes the Active status badge for an active scene" do
      expect(presenter.tree_status_badges).to eq([ { label: "Active", variant: :green } ])
    end

    it "always includes the Resolved status badge for a resolved scene" do
      scene = build(:scene, :resolved)
      expect(described_class.new(scene).tree_status_badges).to eq([ { label: "Resolved", variant: :gray } ])
    end

    it "adds Private after the status badge for a private scene" do
      scene = build(:scene, :private)
      expect(described_class.new(scene).tree_status_badges).to eq([
        { label: "Active", variant: :green },
        { label: "Private", variant: :yellow }
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

  describe "#tree_row_css_class" do
    context "when active" do
      it { expect(presenter.tree_row_css_class).to eq("font-semibold") }
    end

    context "when resolved" do
      let(:scene) { build(:scene, :resolved) }

      it { expect(presenter.tree_row_css_class).to eq("text-slate-500") }
    end
  end

  describe "#tree_link_css_class" do
    context "when active" do
      it { expect(presenter.tree_link_css_class).to eq("") }
    end

    context "when resolved" do
      let(:scene) { build(:scene, :resolved) }

      it { expect(presenter.tree_link_css_class).to eq("text-slate-500") }
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
