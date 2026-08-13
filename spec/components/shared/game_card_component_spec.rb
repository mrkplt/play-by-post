require "rails_helper"

RSpec.describe Shared::GameCardComponent, type: :component do
  let(:game) { build_stubbed(:game, name: "The Sunken Archive") }

  def rendered(**opts)
    defaults = { game: game, can_manage: false, former: false, character_label: nil, active_scene_count: 2 }
    render_inline(described_class.new(**defaults.merge(opts)))
    page
  end

  it "renders the game name linking to the game" do
    expect(rendered).to have_css("a[href='#{"/games/#{game.id}"}']", text: "The Sunken Archive")
  end

  it "shows the active scene count" do
    expect(rendered(active_scene_count: 3)).to have_text("3 active scenes")
  end

  it "singularizes a lone active scene" do
    expect(rendered(active_scene_count: 1)).to have_text("1 active scene")
  end

  it "shows the character label when present" do
    expect(rendered(character_label: "Vex +1")).to have_text("Vex +1")
  end

  it "omits the character line when absent" do
    expect(rendered(character_label: nil)).not_to have_css(".text-row-ink")
  end

  context "GM viewer" do
    it "reports crown" do
      expect(described_class.new(game: game, can_manage: true, former: false, character_label: nil, active_scene_count: 0).show_crown?).to be true
    end
  end

  context "player viewer" do
    it "does not report crown" do
      expect(described_class.new(game: game, can_manage: false, former: false, character_label: nil, active_scene_count: 0).show_crown?).to be false
    end
  end

  context "former (removed) game" do
    subject(:former) { described_class.new(game: game, can_manage: false, former: true, character_label: nil, active_scene_count: 5) }

    it "reads as dormant, not a scene count" do
      expect(former.meta_text).to eq("Not currently active")
    end

    it "takes the blue tint" do
      expect(former.card_classes).to include("bg-tint-blue-bg")
    end

    it "tints the name blue" do
      expect(former.name_classes).to include("text-tint-blue-strong")
    end

    it "tints the meta blue" do
      expect(former.meta_classes).to eq("text-[11px] text-tint-blue-soft")
    end
  end

  context "active game" do
    subject(:active) { described_class.new(game: game, can_manage: false, former: false, character_label: nil, active_scene_count: 2) }

    it "shows a scene count" do
      expect(active.meta_text).to eq("2 active scenes")
    end

    it "takes the white card tint" do
      expect(active.card_classes).to include("bg-card")
    end

    it "uses muted meta classes" do
      expect(active.meta_classes).to eq("text-[11px] text-muted")
    end
  end

  it "glows when new_activity is set" do
    expect(rendered(new_activity: true)).to have_css("a.attn-item.is-hot")
  end

  it "does not glow without new activity" do
    expect(rendered(new_activity: false)).not_to have_css("a.is-hot")
  end

  it "reports new_activity?" do
    expect(described_class.new(game: game, can_manage: false, former: false, character_label: nil, active_scene_count: 0, new_activity: true).new_activity?).to be true
    expect(described_class.new(game: game, can_manage: false, former: false, character_label: nil, active_scene_count: 0).new_activity?).to be false
  end

  it "builds link_data with the new_activity flag only when active" do
    hot = described_class.new(game: game, can_manage: false, former: false, character_label: nil, active_scene_count: 0, new_activity: true)
    cold = described_class.new(game: game, can_manage: false, former: false, character_label: nil, active_scene_count: 0)
    expect(hot.link_data).to eq(new_activity: true)
    expect(cold.link_data).to eq({})
  end

  it "builds exact active name/character classes" do
    c = described_class.new(game: game, can_manage: false, former: false, character_label: "x", active_scene_count: 0)
    expect(c.name_classes).to eq("font-bold text-[15px] text-ink")
    expect(c.character_classes).to eq("text-[13px] text-row-ink")
  end

  it "builds exact former name/character classes" do
    c = described_class.new(game: game, can_manage: false, former: true, character_label: "x", active_scene_count: 0)
    expect(c.name_classes).to eq("font-bold text-[15px] text-tint-blue-strong")
    expect(c.character_classes).to eq("text-[13px] text-tint-blue-soft")
  end

  it "adds is-hot to card_classes only when new_activity" do
    hot = described_class.new(game: game, can_manage: false, former: false, character_label: nil, active_scene_count: 0, new_activity: true)
    cold = described_class.new(game: game, can_manage: false, former: false, character_label: nil, active_scene_count: 0)
    expect(hot.card_classes).to include("is-hot")
    expect(cold.card_classes).not_to include("is-hot")
  end
end
