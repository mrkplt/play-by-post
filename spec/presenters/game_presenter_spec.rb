require "rails_helper"

RSpec.describe GamePresenter do
  let(:game) { build_stubbed(:game) }
  let(:user) { build_stubbed(:user) }
  let(:policy) { instance_double(GamePolicy, manage?: true) }
  let(:urls) { double("urls") }

  subject(:presenter) { described_class.new(game, policy: policy, urls: urls) }

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

  describe "#pending_invitations" do
    it "returns the game's pending invitations, newest first, wrapped as presenters" do
      invitation = build_stubbed(:invitation)
      ordered = [ invitation ]
      all_rel = double("all invitations")
      pending_rel = double("pending invitations")
      ordered_rel = double("ordered invitations")
      allow(game).to receive(:invitations).and_return(all_rel)
      allow(all_rel).to receive(:pending).and_return(pending_rel)
      allow(pending_rel).to receive(:order).with(created_at: :desc).and_return(ordered_rel)
      allow(ordered_rel).to receive(:to_a).and_return(ordered)

      result = presenter.pending_invitations
      expect(result).to all(be_a(InvitationPresenter))
      expect(result.map(&:__getobj__)).to eq(ordered)
    end
  end

  describe "#pages" do
    it "returns the game's pages ordered by title, wrapped as presenters" do
      page = build_stubbed(:page)
      ordered = [ page ]
      all_rel = double("all pages")
      ordered_rel = double("ordered pages")
      allow(game).to receive(:pages).and_return(all_rel)
      allow(all_rel).to receive(:order).with(:title).and_return(ordered_rel)
      allow(ordered_rel).to receive(:to_a).and_return(ordered)

      result = presenter.pages
      expect(result).to all(be_a(PagePresenter))
      expect(result.map(&:__getobj__)).to eq(ordered)
    end
  end

  describe "#links" do
    it "returns the game's links newest first, wrapped as presenters" do
      link = build_stubbed(:game_link)
      ordered = [ link ]
      all_rel = double("all links")
      ordered_rel = double("ordered links")
      allow(game).to receive(:game_links).and_return(all_rel)
      allow(all_rel).to receive(:order).with(created_at: :desc).and_return(ordered_rel)
      allow(ordered_rel).to receive(:to_a).and_return(ordered)

      result = presenter.links
      expect(result).to all(be_a(GameLinkPresenter))
      expect(result.map(&:__getobj__)).to eq(ordered)
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
end
