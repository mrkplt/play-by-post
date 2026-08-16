require "rails_helper"

RSpec.describe Shared::PageVersionHistoryComponent, type: :component do
  let(:game) { build_stubbed(:game) }
  let(:page_record) { build_stubbed(:page, game: game, slug: "abc123def456ghij") }
  let(:version) { build_stubbed(:page_version, page: page_record, created_at: Time.utc(2026, 1, 2, 15, 4)) }
  let(:page_presenter) { PagePresenter.new(page_record) }

  def version_presenter(editor_display_name: "Gandalf the Grey")
    user_presenter = instance_double(UserPresenter, display_name_or_email: editor_display_name)
    allow(UserPresenter).to receive(:new).and_return(user_presenter)
    PageVersionPresenter.new(version)
  end

  def build_component(**overrides)
    described_class.new(
      **{ page: page_presenter, versions: [ version_presenter ] }.merge(overrides)
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
      version_path = Rails.application.routes.url_helpers.game_page_page_version_path(game, page_record, version)
      expect(page).to have_css("summary", text: "Version History (1)")
      expect(page).to have_css("a[href='#{version_path}']", visible: :all)
      expect(page).to have_css("td", text: "Gandalf the Grey", visible: :all)
    end
  end
end
