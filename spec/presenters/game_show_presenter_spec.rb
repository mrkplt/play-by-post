require "rails_helper"

RSpec.describe GameShowPresenter do
  let(:game) { build_stubbed(:game) }
  let(:policy) { instance_double(GamePolicy, manage?: true) }
  let(:urls) { double("urls") }
  let(:helpers) { double("helpers") }
  let(:game_presenter) { GamePresenter.new(game, policy: policy, urls: urls) }
  # Each row's policy is resolved through this injected lambda (view-layering R2);
  # a permissive double is enough — these specs assert wrapping, not capabilities.
  let(:policy_for) { ->(_record) { instance_double(PagePolicy, update?: true, destroy?: true) } }

  subject(:presenter) { described_class.new(game_presenter, urls: urls, helpers: helpers, policy_for: policy_for) }

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
    it "returns every page (including drafts) to a GM, ordered by title, wrapped as presenters" do
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

    it "returns only published pages to a non-GM, hiding drafts" do
      allow(policy).to receive(:manage?).and_return(false)
      page = build_stubbed(:page)
      ordered = [ page ]
      all_rel = double("all pages")
      published_rel = double("published pages")
      ordered_rel = double("ordered pages")
      allow(game).to receive(:pages).and_return(all_rel)
      allow(all_rel).to receive(:published).and_return(published_rel)
      allow(published_rel).to receive(:order).with(:title).and_return(ordered_rel)
      allow(ordered_rel).to receive(:to_a).and_return(ordered)

      result = presenter.pages
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

  describe "#game_files" do
    it "returns the game's files, newest first, wrapped as presenters" do
      file = build_stubbed(:game_file)
      includes_rel = double("includes rel")
      ordered_rel = double("ordered rel")
      allow(game).to receive(:game_files).and_return(double(includes: includes_rel))
      allow(includes_rel).to receive(:order).with(created_at: :desc).and_return(ordered_rel)
      allow(ordered_rel).to receive(:to_a).and_return([ file ])

      result = presenter.game_files
      expect(result.length).to eq(1)
      expect(result.first).to be_a(GameFilePresenter)
    end
  end

  describe "#game_files?" do
    it "is true when the game has files" do
      file = build_stubbed(:game_file)
      includes_rel = double("includes rel")
      ordered_rel = double("ordered rel")
      allow(game).to receive(:game_files).and_return(double(includes: includes_rel))
      allow(includes_rel).to receive(:order).with(created_at: :desc).and_return(ordered_rel)
      allow(ordered_rel).to receive(:to_a).and_return([ file ])

      expect(presenter.game_files?).to be(true)
    end

    it "is false when the game has no files" do
      includes_rel = double("includes rel")
      ordered_rel = double("ordered rel")
      allow(game).to receive(:game_files).and_return(double(includes: includes_rel))
      allow(includes_rel).to receive(:order).with(created_at: :desc).and_return(ordered_rel)
      allow(ordered_rel).to receive(:to_a).and_return([])

      expect(presenter.game_files?).to be(false)
    end
  end

  describe "#new_game_file" do
    it "returns a blank file record wrapped for the upload form" do
      blank = build_stubbed(:game_file)
      allow(game).to receive(:game_files).and_return(double(new: blank))

      expect(presenter.new_game_file).to be_a(GameFilePresenter)
    end
  end
end
