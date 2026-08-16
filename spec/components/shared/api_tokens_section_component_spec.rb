require "rails_helper"

RSpec.describe Shared::ApiTokensSectionComponent, type: :component do
  let(:game) { build_stubbed(:game, name: "Ashfall Reaches") }
  let(:urls) { vc_test_view_context }

  def row(token: nil)
    ApiTokenRowPresenter.new(game, token: token, urls: urls)
  end

  context "when a game has no token" do
    it "renders a create-token control for the game" do
      render_inline(described_class.new(rows: [ row ]))
      expect(page).to have_button("Create token")
      expect(page).to have_text("Ashfall Reaches")
      expect(page).not_to have_button("Revoke")
    end

    it "posts scope: \"api\" on the create control" do
      render_inline(described_class.new(rows: [ row ]))
      expect(page).to have_css(%(input[type="hidden"][name="scope"][value="api"]), visible: :all)
    end

    it "posts the game id on the create control" do
      render_inline(described_class.new(rows: [ row ]))
      expect(page).to have_css(%(input[type="hidden"][name="game_id"][value="#{game.id}"]), visible: :all)
    end
  end

  context "when a game has an api token" do
    let(:token) { build_stubbed(:api_token, game: game, scope: "api", token: "sekret") }

    it "renders the masked token value and a revoke control" do
      render_inline(described_class.new(rows: [ row(token: token) ]))
      expect(page).to have_css(".secret-field")
      expect(page).to have_button("Revoke")
      expect(page).not_to have_button("Create token")
    end

    it "feeds the raw token value into the secret field" do
      render_inline(described_class.new(rows: [ row(token: token) ]))
      expect(page).to have_css(%(.secret-field[data-secret-field-value-value="sekret"]))
    end
  end

  describe "#any_games?" do
    it "is false with no rows" do
      expect(described_class.new(rows: []).any_games?).to be(false)
    end

    it "is true with a row" do
      expect(described_class.new(rows: [ row ]).any_games?).to be(true)
    end
  end

  describe "#row_position" do
    it "is :last only for the final index" do
      component = described_class.new(rows: [ row, row ])
      expect(component.row_position(0)).to eq(:middle)
      expect(component.row_position(1)).to eq(:last)
    end
  end
end
