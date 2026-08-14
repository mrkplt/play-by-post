require "rails_helper"

RSpec.describe Shared::CharacterVersionHistoryComponent, type: :component do
  let(:game) { build_stubbed(:game) }
  let(:character) { build_stubbed(:character, game: game) }
  let(:version) { build_stubbed(:character_version, character: character, created_at: Time.utc(2026, 1, 2, 15, 4)) }
  let(:game_presenter) { GamePresenter.new(game, policy: instance_double(GamePolicy)) }
  let(:character_presenter) do
    CharacterPresenter.new(character, game_policy: instance_double(GamePolicy), character_policy: instance_double(CharacterPolicy))
  end
  let(:version_presenter) { CharacterVersionPresenter.new(version, editor_name: "Gandalf the Grey") }

  def build_component(**overrides)
    described_class.new(
      **{
        game: game_presenter,
        character: character_presenter,
        versions: [ version_presenter ]
      }.merge(overrides)
    )
  end

  describe "#version_count" do
    it "counts the supplied versions" do
      expect(build_component.version_count).to eq(1)
      expect(build_component(versions: []).version_count).to eq(0)
    end
  end

  describe "rendering" do
    it "renders a disclosure titled with the version count and a row per version" do
      render_inline(build_component)
      version_path = Rails.application.routes.url_helpers.game_character_character_version_path(game, character, version)
      expect(page).to have_css("summary", text: "Version History (1)")
      expect(page).to have_css("a[href='#{version_path}']", visible: :all)
      expect(page).to have_css("td", text: "Gandalf the Grey", visible: :all)
    end
  end
end
