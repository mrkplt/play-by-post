require "rails_helper"

RSpec.describe GamePresenter do
  let(:game) { build_stubbed(:game) }
  let(:policy) { instance_double(GamePolicy, manage?: true) }
  let(:urls) { double("urls") }

  subject(:presenter) { described_class.new(game, policy: policy, urls: urls) }

  describe "#model" do
    it "returns the wrapped game" do
      expect(presenter.model).to eq(game)
    end
  end

  describe "#can_manage?" do
    it "is true when the injected policy allows management" do
      allow(policy).to receive(:manage?).and_return(true)
      expect(presenter.can_manage?).to be(true)
    end

    it "is false when the injected policy disallows management" do
      allow(policy).to receive(:manage?).and_return(false)
      expect(presenter.can_manage?).to be(false)
    end
  end

  describe "#can_contribute?" do
    it "is true when the injected policy allows contributing" do
      allow(policy).to receive(:contribute?).and_return(true)
      expect(presenter.can_contribute?).to be(true)
    end

    it "is false when the injected policy disallows contributing" do
      allow(policy).to receive(:contribute?).and_return(false)
      expect(presenter.can_contribute?).to be(false)
    end
  end

  describe "#player_contributions_enabled?" do
    it "is true when the game has player contributions enabled" do
      allow(game).to receive(:player_contributions_enabled?).and_return(true)
      expect(presenter.player_contributions_enabled?).to be(true)
    end

    it "is false when the game has player contributions disabled" do
      allow(game).to receive(:player_contributions_enabled?).and_return(false)
      expect(presenter.player_contributions_enabled?).to be(false)
    end
  end

  describe "#notebook_board" do
    it "wraps the game in a NotebookBoardPresenter" do
      expect(presenter.notebook_board).to be_a(NotebookBoardPresenter)
    end
  end

  describe "#sheets_hidden?" do
    it "is true when the game has sheets hidden" do
      allow(game).to receive(:sheets_hidden?).and_return(true)
      expect(presenter.sheets_hidden?).to be(true)
    end

    it "is false when the game has sheets visible" do
      allow(game).to receive(:sheets_hidden?).and_return(false)
      expect(presenter.sheets_hidden?).to be(false)
    end
  end

  describe "#errors?" do
    it "is false on a clean game" do
      expect(presenter.errors?).to be(false)
    end

    it "is true when the game has errors" do
      game.errors.add(:name, "can't be blank")
      expect(presenter.errors?).to be(true)
    end
  end

  describe "#error_messages" do
    it "returns the game's full error messages" do
      game.errors.add(:name, "can't be blank")
      expect(presenter.error_messages).to include("Name can't be blank")
    end
  end

  describe "#ai_summaries_enabled?" do
    it "delegates to the model" do
      allow(game).to receive(:ai_summaries_enabled?).and_return(true)
      expect(presenter.ai_summaries_enabled?).to be(true)
    end
  end

  describe "#id" do
    it "delegates to the model" do
      expect(presenter.id).to eq(game.id)
    end
  end



  describe "#description" do
    it "delegates to the model" do
      expect(presenter.description).to eq(game.description)
    end
  end

  it "delegates model methods to the game" do
    expect(presenter.name).to eq(game.name)
  end



  describe "#export_notice", :db do
    let(:game) { create(:game) }

    it "is nil when the viewer has no valid receipt for this game" do
      user_record = create(:user)
      presenter = described_class.new(game, policy: policy, current_user: user_record)
      expect(presenter.export_notice).to be_nil
    end

    it "reports how long ago the viewer's receipt for this game succeeded" do
      user_record = create(:user)
      receipt = create(:game_export_request, user: user_record, game: game, succeeded_at: 2.hours.ago)
      receipt.archive.attach(io: StringIO.new("zip"), filename: "e.zip", content_type: "application/zip")

      presenter = described_class.new(game, policy: policy, current_user: user_record)
      expect(presenter.export_notice).to match(/Last export: .+ ago/)
    end
  end
end
