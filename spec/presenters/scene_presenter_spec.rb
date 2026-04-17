require "rails_helper"

RSpec.describe ScenePresenter do
  let(:scene) { build(:scene, created_at: Time.zone.parse("2024-03-10 09:00:00")) }

  subject(:presenter) { described_class.new(scene) }

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

  describe "#formatted_created_at" do
    it "formats the timestamp" do
      expect(presenter.formatted_created_at).to eq("Mar 10, 2024  9:00am")
    end
  end

  describe "#participant_names" do
    it "returns empty string when no participants with characters" do
      allow(scene).to receive(:scene_participants).and_return(
        double(includes: [])
      )
      expect(presenter.participant_names).to eq("")
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
