require "rails_helper"

RSpec.describe SceneSummaryPresenter do
  let(:summary) { build_stubbed(:scene_summary, body: "**Hero** wins.") }
  subject(:presenter) { described_class.new(summary) }

  describe "#status_label" do
    context "when hand-written" do
      it "returns 'Hand-written'" do
        expect(presenter.status_label).to eq("Hand-written")
      end
    end

    context "when AI-generated and not edited" do
      let(:summary) { build_stubbed(:scene_summary, :ai_generated, edited_at: nil) }

      it "returns 'AI-generated'" do
        expect(presenter.status_label).to eq("AI-generated")
      end
    end

    context "when AI-generated and then edited" do
      let(:summary) { build_stubbed(:scene_summary, :ai_generated, :edited) }

      it "returns 'Edited'" do
        expect(presenter.status_label).to eq("Edited")
      end
    end
  end

  describe "#formatted_generated_at" do
    it "returns nil when not AI-generated" do
      expect(presenter.formatted_generated_at).to be_nil
    end

    context "when AI-generated" do
      let(:summary) { build_stubbed(:scene_summary, :ai_generated, generated_at: Time.zone.parse("2026-04-01 12:00")) }

      it "formats the date" do
        expect(presenter.formatted_generated_at).to eq("Apr 1, 2026")
      end
    end
  end

  describe "#formatted_edited_at" do
    it "returns nil when not edited" do
      expect(presenter.formatted_edited_at).to be_nil
    end

    context "when edited" do
      let(:summary) { build_stubbed(:scene_summary, :edited, edited_at: Time.zone.parse("2026-05-15 09:30")) }

      it "formats the date" do
        expect(presenter.formatted_edited_at).to eq("May 15, 2026")
      end
    end
  end

  describe "#ai_generated?" do
    it "delegates to the model" do
      expect(presenter.ai_generated?).to eq(summary.ai_generated?)
    end
  end

  describe "#edited?" do
    it "delegates to the model" do
      expect(presenter.edited?).to eq(summary.edited?)
    end
  end

  describe "#scene_title" do
    it "returns the scene's title" do
      scene = build_stubbed(:scene, title: "The Fall of Vex")
      allow(summary).to receive(:scene).and_return(scene)
      expect(presenter.scene_title).to eq("The Fall of Vex")
    end
  end

  describe "#formatted_scene_resolved_at" do
    it "returns nil when the scene has no resolved_at" do
      scene = build_stubbed(:scene, resolved_at: nil)
      allow(summary).to receive(:scene).and_return(scene)
      expect(presenter.formatted_scene_resolved_at).to be_nil
    end

    context "when the scene is resolved" do
      it "formats the date" do
        scene = build_stubbed(:scene, resolved_at: Time.zone.parse("2026-03-10"))
        allow(summary).to receive(:scene).and_return(scene)
        expect(presenter.formatted_scene_resolved_at).to eq("Mar 10, 2026")
      end
    end
  end

  describe "#can_manage?" do
    subject(:presenter) { described_class.new(summary, policy: policy) }

    context "when the policy allows managing the summary" do
      let(:policy) { instance_double(SceneSummaryPolicy, manage?: true) }

      it "returns true" do
        expect(presenter.can_manage?).to be(true)
      end
    end

    context "when the policy forbids managing the summary" do
      let(:policy) { instance_double(SceneSummaryPolicy, manage?: false) }

      it "returns false" do
        expect(presenter.can_manage?).to be(false)
      end
    end
  end

  describe "#scene_path" do
    it "builds the scene's show path from the injected game and url_helpers" do
      game = build_stubbed(:game, id: 7)
      scene = build_stubbed(:scene, id: 42)
      allow(summary).to receive(:scene).and_return(scene)
      urls = double("urls")
      allow(urls).to receive(:game_scene_path).with(game, scene).and_return("/games/7/scenes/42")

      presenter = described_class.new(summary, game: game, urls: urls)
      expect(presenter.scene_path).to eq("/games/7/scenes/42")
    end
  end

  describe "#edit_path" do
    it "builds the summary's edit path from the injected game and url_helpers" do
      game = build_stubbed(:game, id: 7)
      scene = build_stubbed(:scene, id: 42)
      allow(summary).to receive(:scene).and_return(scene)
      urls = double("urls")
      allow(urls).to receive(:edit_game_scene_scene_summary_path).with(game, scene)
        .and_return("/games/7/scenes/42/scene_summary/edit")

      presenter = described_class.new(summary, game: game, urls: urls)
      expect(presenter.edit_path).to eq("/games/7/scenes/42/scene_summary/edit")
    end
  end

  describe "#submit_path" do
    it "builds the summary's resource path from the injected game and url_helpers" do
      game = build_stubbed(:game, id: 7)
      scene = build_stubbed(:scene, id: 42)
      allow(summary).to receive(:scene).and_return(scene)
      urls = double("urls")
      allow(urls).to receive(:game_scene_scene_summary_path).with(game, scene)
        .and_return("/games/7/scenes/42/scene_summary")

      presenter = described_class.new(summary, game: game, urls: urls)
      expect(presenter.submit_path).to eq("/games/7/scenes/42/scene_summary")
    end
  end

  describe "#status_label" do
    it "requires both ai_generated? and edited? to return 'Edited'" do
      ai_only = build_stubbed(:scene_summary, :ai_generated, edited_at: nil)
      expect(described_class.new(ai_only).status_label).to eq("AI-generated")
    end

    it "returns 'Hand-written' when edited but not AI-generated" do
      edited_manual = build_stubbed(:scene_summary, :edited, generated_at: nil)
      expect(described_class.new(edited_manual).status_label).to eq("Hand-written")
    end
  end
end
