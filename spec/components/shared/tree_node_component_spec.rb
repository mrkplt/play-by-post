require "rails_helper"

RSpec.describe Shared::TreeNodeComponent, type: :component do
  let(:game)  { build_stubbed(:game) }
  let(:scene) { build_stubbed(:scene, game: game, title: "The Keep", created_at: Time.zone.parse("2024-04-01 10:00:00")) }
  let(:node)  { { scene: scene, children: [] } }

  subject(:component) { described_class.new(node: node, game: game, depth: 0) }

  def rendered_component
    render_inline(component)
    page
  end

  it "renders the scene title as a link" do
    expect(rendered_component).to have_css("a", text: "The Keep")
  end

  it "renders the active badge for an active scene" do
    expect(rendered_component).to have_css("[data-variant=green]", text: "Active")
  end

  it "does not render the connector at depth 0" do
    expect(rendered_component).not_to have_text("└─")
  end

  it "renders the formatted created_at timestamp" do
    expect(rendered_component).to have_text("Apr 1, 2024")
  end

  context "when resolved" do
    let(:scene) { build_stubbed(:scene, :resolved, game: game, title: "The Keep", created_at: Time.current) }

    it "renders the resolved badge" do
      expect(rendered_component).to have_css("[data-variant=gray]", text: "Resolved")
    end
  end

  context "when private" do
    let(:scene) { build_stubbed(:scene, :private, game: game, title: "The Keep", created_at: Time.current) }

    it "renders the private badge" do
      expect(rendered_component).to have_css("[data-variant=yellow]", text: "Private")
    end
  end

  context "at depth > 0" do
    subject(:component) { described_class.new(node: node, game: game, depth: 1) }

    it "renders the tree connector" do
      expect(rendered_component).to have_text("└─")
    end

    it "applies indentation" do
      expect(rendered_component).to have_css("[style*='margin-left:1.5rem']")
    end
  end

  context "with children" do
    let(:child_scene) { build_stubbed(:scene, game: game, title: "The Cellar", created_at: Time.current) }
    let(:node) { { scene: scene, children: [ { scene: child_scene, children: [] } ] } }

    it "renders the child scene title" do
      expect(rendered_component).to have_css("a", text: "The Cellar")
    end

    it "renders the child connector" do
      expect(rendered_component).to have_text("└─")
    end
  end
end
