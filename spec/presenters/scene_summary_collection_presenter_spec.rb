require "rails_helper"

RSpec.describe SceneSummaryCollectionPresenter do
  let(:game) { build_stubbed(:game) }
  let(:urls) { double("urls") }
  let(:pagy) { double("Pagy", series_nav: "<nav>...</nav>") }

  describe "#empty?" do
    it "is true when there are no summaries" do
      presenter = described_class.new([], game: game, urls: urls, pagy: pagy)
      expect(presenter.empty?).to be(true)
    end

    it "is false when there are summaries" do
      summary = build_stubbed(:scene_summary)
      presenter = described_class.new([ summary ], game: game, urls: urls, pagy: pagy)
      expect(presenter.empty?).to be(false)
    end
  end

  describe "#entries" do
    it "wraps each summary in a SceneSummaryPresenter carrying the injected game and url_helpers" do
      summary = build_stubbed(:scene_summary)
      presenter = described_class.new([ summary ], game: game, urls: urls, pagy: pagy)

      entries = presenter.entries
      expect(entries.length).to eq(1)
      expect(entries.first).to be_a(SceneSummaryPresenter)
      expect(entries.first.__getobj__).to eq(summary)
    end

    it "is empty when there are no summaries" do
      presenter = described_class.new([], game: game, urls: urls, pagy: pagy)
      expect(presenter.entries).to eq([])
    end

    it "threads the injected viewer through to each wrapped presenter" do
      summary = build_stubbed(:scene_summary, :ai_generated)
      viewer = build_stubbed(:user, user_profile: build_stubbed(:user_profile, ai_display_preference: :shown))
      presenter = described_class.new([ summary ], game: game, urls: urls, pagy: pagy, viewer: viewer)

      expect(presenter.entries.first.show_ai_badge?).to be(false)
    end

    it "defaults the wrapped presenter's viewer to nil when none is supplied" do
      summary = build_stubbed(:scene_summary, :ai_generated)
      presenter = described_class.new([ summary ], game: game, urls: urls, pagy: pagy)

      expect(presenter.entries.first.show_ai_badge?).to be(true)
    end

    it "threads the injected game and urls to each wrapped presenter's routes" do
      scene = build_stubbed(:scene)
      summary = build_stubbed(:scene_summary, scene: scene)
      urls = double("urls", game_scene_path: "/games/1/scenes/2")
      presenter = described_class.new([ summary ], game: game, urls: urls, pagy: pagy)

      presenter.entries.first.routes.scene_path

      expect(urls).to have_received(:game_scene_path).with(game, scene)
    end
  end

  describe "#pagy_nav" do
    it "delegates to the injected pagy object's series_nav" do
      presenter = described_class.new([], game: game, urls: urls, pagy: pagy)
      expect(presenter.pagy_nav).to eq("<nav>...</nav>")
    end
  end
end
