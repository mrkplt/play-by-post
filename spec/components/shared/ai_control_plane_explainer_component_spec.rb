require "rails_helper"

RSpec.describe Shared::AiControlPlaneExplainerComponent, type: :component do
  def rendered
    render_inline(described_class.new)
  end

  describe "SECTIONS" do
    it "defines five sections" do
      expect(described_class::SECTIONS.length).to eq(5)
    end

    it "gives every section a heading and at least one paragraph" do
      described_class::SECTIONS.each do |section|
        expect(section.heading).to be_present
        expect(section.paragraphs).to be_present
        expect(section.paragraphs).to all(be_present)
      end
    end
  end

  describe "rendering" do
    it "renders every section heading" do
      described_class::SECTIONS.each do |section|
        expect(rendered).to have_text(section.heading)
      end
    end

    it "renders every paragraph" do
      described_class::SECTIONS.each do |section|
        section.paragraphs.each do |paragraph|
          expect(rendered).to have_text(paragraph)
        end
      end
    end

    it "explains that the plaintext key is never seen by the app" do
      expect(rendered).to have_text("We never see your key in plaintext")
    end

    it "explains that an empty pool means generation is refused" do
      expect(rendered).to have_text("generation is simply refused")
    end

    it "describes the shown/tagged/hidden display preference" do
      body = rendered.to_html
      expect(body).to include("Shown")
      expect(body).to include("Tagged")
      expect(body).to include("Hidden")
    end
  end
end
