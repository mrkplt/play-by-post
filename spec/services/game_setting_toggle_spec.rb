require "rails_helper"

RSpec.describe GameSettingToggle, :db do
  let(:game) { create(:game) }

  describe "#call" do
    it "turns a setting on and says so" do
      game.update!(sheets_hidden: false)

      expect(described_class.new(game, :sheets_hidden).call).to eq("Character sheets are now hidden.")
      expect(game.reload.sheets_hidden?).to be(true)
    end

    it "turns a setting off and says so" do
      game.update!(sheets_hidden: true)

      expect(described_class.new(game, :sheets_hidden).call).to eq("Character sheets are now visible.")
      expect(game.reload.sheets_hidden?).to be(false)
    end

    it "words the AI summaries setting for its own flag" do
      game.update!(ai_summaries_enabled: false)

      expect(described_class.new(game, :ai_summaries_enabled).call).to eq("AI scene summaries enabled.")
    end

    it "words the AI summaries setting when switched off" do
      game.update!(ai_summaries_enabled: true)

      expect(described_class.new(game, :ai_summaries_enabled).call).to eq("AI scene summaries disabled.")
    end

    it "persists the flip" do
      game.update!(ai_summaries_enabled: false)

      expect { described_class.new(game, :ai_summaries_enabled).call }
        .to change { game.reload.ai_summaries_enabled? }.from(false).to(true)
    end

    it "words player contributions when switched on" do
      game.update!(player_contributions_enabled: false)

      expect(described_class.new(game, :player_contributions_enabled).call)
        .to eq("Players can now add pages, links, and files.")
      expect(game.reload.player_contributions_enabled?).to be(true)
    end

    it "words player contributions when switched off" do
      game.update!(player_contributions_enabled: true)

      expect(described_class.new(game, :player_contributions_enabled).call)
        .to eq("Player contributions are now off.")
      expect(game.reload.player_contributions_enabled?).to be(false)
    end
  end
end
