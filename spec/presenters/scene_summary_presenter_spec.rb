require "rails_helper"

RSpec.describe SceneSummaryPresenter do
  let(:summary) { build_stubbed(:scene_summary, body: "**Hero** wins.") }
  subject(:presenter) { described_class.new(summary) }

  describe "#rendered_body" do
    it "renders markdown to HTML" do
      expect(presenter.rendered_body).to include("<strong>Hero</strong>")
    end
  end

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
end
