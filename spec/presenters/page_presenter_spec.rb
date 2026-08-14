require "rails_helper"

RSpec.describe PagePresenter do
  let(:game) { build_stubbed(:game) }
  let(:page_record) { build_stubbed(:page, game: game, title: "Lore", body: "# Heading") }
  let(:policy) { instance_double(PagePolicy, manage?: true) }

  subject(:presenter) { described_class.new(page_record, policy: policy) }

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

  describe "#game" do
    it "returns the page's game" do
      expect(presenter.game).to eq(game)
    end
  end

  describe "#title" do
    it "returns the page's title" do
      expect(presenter.title).to eq("Lore")
    end
  end

  describe "#body" do
    it "returns the page's body" do
      expect(presenter.body).to eq("# Heading")
    end
  end

  describe "#body?" do
    it "is true when the page has body content" do
      expect(presenter.body?).to be(true)
    end

    it "is false when the page has no body" do
      empty_page = build_stubbed(:page, game: game, body: nil)
      expect(described_class.new(empty_page, policy: policy).body?).to be(false)
    end
  end

  describe "#new_record?" do
    it "is true for an unpersisted page" do
      expect(described_class.new(game.pages.new, policy: policy).new_record?).to be(true)
    end

    it "is false for a persisted page" do
      expect(presenter.new_record?).to be(false)
    end
  end

  describe "#errors?" do
    it "reports no errors on a clean page" do
      expect(presenter.errors?).to be(false)
    end

    it "reports errors when the page has validation errors" do
      page_record.errors.add(:title, "can't be blank")
      expect(presenter.errors?).to be(true)
    end
  end

  describe "#error_messages" do
    it "surfaces full validation messages" do
      page_record.errors.add(:title, "can't be blank")
      expect(presenter.error_messages).to include("Title can't be blank")
    end
  end
end
