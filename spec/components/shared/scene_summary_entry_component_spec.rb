require "rails_helper"

RSpec.describe Shared::SceneSummaryEntryComponent, type: :component do
  let(:game) { build_stubbed(:game) }
  let(:scene) { build_stubbed(:scene, game: game, title: "The Cavern", resolved_at: Time.zone.parse("2026-03-10")) }
  let(:summary) { build_stubbed(:scene_summary, scene: scene, body: "A **brave** expedition.") }
  let(:presenter) { SceneSummaryPresenter.new(summary) }

  def rendered_component
    render_inline(described_class.new(summary: presenter, game: game))
    page
  end

  it "renders the scene title" do
    expect(rendered_component).to have_text("The Cavern")
  end

  it "renders a link to the scene" do
    expect(rendered_component).to have_css("a", text: "The Cavern")
  end

  it "renders the resolution date" do
    expect(rendered_component).to have_text("Mar 10, 2026")
  end

  it "renders the summary body as markdown" do
    expect(rendered_component).to have_css("strong", text: "brave")
  end
end
