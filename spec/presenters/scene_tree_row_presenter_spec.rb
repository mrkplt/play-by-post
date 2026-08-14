require "rails_helper"

RSpec.describe SceneTreeRowPresenter do
  let(:scene) { build(:scene, created_at: Time.zone.parse("2024-03-10 09:00:00")) }
  let(:scene_presenter) { ScenePresenter.new(scene) }

  subject(:presenter) { described_class.new(scene_presenter) }

  describe "#title" do
    it "delegates to the wrapped scene presenter" do
      expect(presenter.title).to eq(scene.title)
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

  describe "#tree_status_badges" do
    it "always includes the Active status badge for an active scene" do
      expect(presenter.tree_status_badges).to eq([ { label: "Active", variant: :green } ])
    end

    it "always includes the Resolved status badge for a resolved scene" do
      scene = build(:scene, :resolved)
      expect(described_class.new(ScenePresenter.new(scene)).tree_status_badges).to eq([
        { label: "Resolved", variant: :gray }
      ])
    end

    it "adds Private after the status badge for a private scene" do
      scene = build(:scene, :private)
      expect(described_class.new(ScenePresenter.new(scene)).tree_status_badges).to eq([
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
end
