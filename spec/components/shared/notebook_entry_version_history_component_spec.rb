require "rails_helper"

RSpec.describe Shared::NotebookEntryVersionHistoryComponent, type: :component do
  let(:game) { build_stubbed(:game, slug: "game123def456ghi") }
  let(:entry) { build_stubbed(:notebook_entry, game: game, slug: "abc123def456ghij") }
  let(:version) do
    build_stubbed(:notebook_entry_version, notebook_entry: entry, created_at: Time.utc(2026, 1, 2, 15, 4))
  end
  let(:game_presenter) { GamePresenter.new(game) }
  let(:entry_presenter) { NotebookEntryPresenter.new(entry) }

  def version_presenter(editor_display_name: "Gandalf the Grey")
    user_presenter = instance_double(UserPresenter, display_name_or_email: editor_display_name)
    allow(UserPresenter).to receive(:new).and_return(user_presenter)
    NotebookEntryVersionPresenter.new(version)
  end

  def build_component(**overrides)
    described_class.new(
      **{ game: game_presenter, entry: entry_presenter, versions: [ version_presenter ] }.merge(overrides)
    )
  end

  describe "rendering" do
    it "renders a disclosure titled with the version count and a row per version" do
      render_inline(build_component)
      version_path = Rails.application.routes.url_helpers
        .game_notebook_entry_notebook_entry_version_path(game, entry, version)
      expect(page).to have_css("summary", text: "Version History (1)")
      expect(page).to have_css("a[href='#{version_path}']", visible: :all)
      expect(page).to have_css("td", text: "Gandalf the Grey", visible: :all)
    end

    it "renders an empty history" do
      render_inline(build_component(versions: []))
      expect(page).to have_css("summary", text: "Version History (0)")
    end
  end
end
