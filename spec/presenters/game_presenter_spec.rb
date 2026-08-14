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

  describe "#notebook_board" do
    it "wraps the game in a NotebookBoardPresenter" do
      expect(presenter.notebook_board).to be_a(NotebookBoardPresenter)
    end
  end

  describe "#images_disabled?" do
    it "is true when the game has images disabled" do
      allow(game).to receive(:images_disabled?).and_return(true)
      expect(presenter.images_disabled?).to be(true)
    end

    it "is false when the game has images enabled" do
      allow(game).to receive(:images_disabled?).and_return(false)
      expect(presenter.images_disabled?).to be(false)
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

  describe "#ai_summaries_toggle_aria_label" do
    it "describes disabling the toggle when summaries are enabled" do
      allow(game).to receive(:ai_summaries_enabled?).and_return(true)
      expect(presenter.ai_summaries_toggle_aria_label).to eq("Disable AI scene summaries")
    end

    it "describes enabling the toggle when summaries are disabled" do
      allow(game).to receive(:ai_summaries_enabled?).and_return(false)
      expect(presenter.ai_summaries_toggle_aria_label).to eq("Enable AI scene summaries")
    end
  end

  describe "#id" do
    it "delegates to the model" do
      expect(presenter.id).to eq(game.id)
    end
  end

  describe "#new_scene_path" do
    it "builds the new-scene path from the injected url_helpers" do
      allow(urls).to receive(:new_game_scene_path).with(game).and_return("/games/#{game.id}/scenes/new")
      expect(presenter.new_scene_path).to eq("/games/#{game.id}/scenes/new")
    end
  end

  describe "#edit_path" do
    it "builds the game's edit path from the injected url_helpers" do
      allow(urls).to receive(:edit_game_path).with(game).and_return("/games/#{game.id}/edit")
      expect(presenter.edit_path).to eq("/games/#{game.id}/edit")
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

  describe "#notebook_board_href" do
    it "resolves the game's Campaign Notebook board URL" do
      allow(urls).to receive(:game_notebook_entries_path).with(game).and_return("/games/1/notebook_entries")
      expect(presenter.notebook_board_href).to eq("/games/1/notebook_entries")
    end
  end

  describe "#owner_options" do
    it "is empty when the game has no active players" do
      members_rel = double("members rel")
      where_rel = double("where rel")
      allow(game).to receive(:active_members).and_return(members_rel)
      allow(members_rel).to receive(:where).with(role: "player").and_return(where_rel)
      allow(where_rel).to receive(:includes).with(:user).and_return([])

      expect(presenter.owner_options).to eq([])
    end

    it "pairs each active player's display name (falling back to email) with their id" do
      named = build_stubbed(:user, email: "elf@example.com")
      allow(named).to receive(:display_name).and_return("Elrond")
      nameless = build_stubbed(:user, email: "orc@example.com")
      allow(nameless).to receive(:display_name).and_return(nil)

      named_membership = instance_double(GameMember, user: named)
      nameless_membership = instance_double(GameMember, user: nameless)

      members_rel = double("members rel")
      where_rel = double("where rel")
      allow(game).to receive(:active_members).and_return(members_rel)
      allow(members_rel).to receive(:where).with(role: "player").and_return(where_rel)
      allow(where_rel).to receive(:includes).with(:user).and_return([ named_membership, nameless_membership ])

      expect(presenter.owner_options).to eq([ [ "Elrond", named.id ], [ "orc@example.com", nameless.id ] ])
    end
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
