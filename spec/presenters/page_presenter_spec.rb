require "rails_helper"

RSpec.describe PagePresenter do
  let(:page_record) { build_stubbed(:page, title: "Lore") }
  let(:game_policy) { instance_double(GamePolicy, manage?: true) }
  let(:page_policy) { instance_double(PagePolicy, manage?: true) }

  subject(:presenter) { described_class.new(page_record, game_policy: game_policy, page_policy: page_policy) }

  describe "#can_manage_game?" do
    it "is true when the injected game policy allows management" do
      allow(game_policy).to receive(:manage?).and_return(true)
      expect(presenter.can_manage_game?).to be(true)
    end

    it "is false when the injected game policy disallows management" do
      allow(game_policy).to receive(:manage?).and_return(false)
      expect(presenter.can_manage_game?).to be(false)
    end
  end

  describe "#can_manage?" do
    it "is true when the injected page policy allows management" do
      allow(page_policy).to receive(:manage?).and_return(true)
      expect(presenter.can_manage?).to be(true)
    end

    it "is false when the injected page policy disallows management" do
      allow(page_policy).to receive(:manage?).and_return(false)
      expect(presenter.can_manage?).to be(false)
    end
  end

  describe "#new_record?" do
    it "is true for an unpersisted page" do
      unsaved = described_class.new(Page.new, game_policy: game_policy, page_policy: page_policy)
      expect(unsaved.new_record?).to be(true)
    end

    it "is false for a persisted page" do
      expect(presenter.new_record?).to be(false)
    end
  end

  describe "#id" do
    it "returns the underlying id" do
      expect(presenter.id).to eq(page_record.id)
    end
  end

  describe "#title" do
    it "returns the underlying title" do
      expect(presenter.title).to eq("Lore")
    end
  end

  describe "#body?" do
    it "is true when the page has body content" do
      expect(described_class.new(build_stubbed(:page, body: "content"), game_policy: game_policy, page_policy: page_policy).body?).to be(true)
    end

    it "is false when the page has no body content" do
      expect(described_class.new(build_stubbed(:page, body: ""), game_policy: game_policy, page_policy: page_policy).body?).to be(false)
    end
  end

  describe "#body" do
    it "returns the body content" do
      with_body = described_class.new(build_stubbed(:page, body: "# Heading"), game_policy: game_policy, page_policy: page_policy)
      expect(with_body.body).to eq("# Heading")
    end
  end

  describe "#errors?" do
    it "is false with no errors" do
      expect(presenter.errors?).to be(false)
    end

    it "is true when the page has errors" do
      page_record.errors.add(:title, "can't be blank")
      expect(presenter.errors?).to be(true)
    end
  end

  describe "#error_messages" do
    it "returns full error messages" do
      page_record.errors.add(:title, "can't be blank")
      expect(presenter.error_messages).to include("Title can't be blank")
    end
  end

  describe "#to_model" do
    it "returns the underlying model" do
      expect(presenter.to_model).to eq(page_record)
    end
  end
end
