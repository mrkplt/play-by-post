require "rails_helper"

RSpec.describe Shared::NotebookLaneSelectComponent, type: :component do
  let(:game) { build_stubbed(:game) }
  let(:entry) { build_stubbed(:notebook_entry, game: game, title: "Idea", slug: "abc123def456ghij") }

  def build_component(**overrides)
    described_class.new(**{ game: game, notebook_entry: entry }.merge(overrides))
  end

  def move_path
    Rails.application.routes.url_helpers.move_game_notebook_entry_path(game, entry)
  end

  describe "#status_options" do
    it "includes every status with a human label" do
      expect(build_component.status_options)
        .to eq([ [ "New", "new" ], [ "Expand", "expand" ], [ "Done", "done" ], [ "Discard", "discard" ] ])
    end

    it "covers every status the model allows" do
      expect(build_component.status_options.map(&:last)).to match_array(NotebookEntry::STATUSES)
    end
  end

  describe "#selected_status" do
    it "reports the entry's current lane" do
      expect(build_component.selected_status).to eq("new")
    end
  end

  describe "rendering" do
    it "posts to the entry's move route as a PATCH" do
      render_inline(build_component)
      expect(page).to have_css("form[action='#{move_path}']")
      expect(page).to have_field("_method", type: :hidden, with: "patch")
    end

    it "submits itself on change so no separate button is needed" do
      render_inline(build_component)
      expect(page.find("select[name='notebook_entry[status]']")["onchange"]).to eq("this.form.requestSubmit()")
      expect(page).to have_no_button
    end

    it "drives the move over a Turbo Stream so the board does not navigate" do
      render_inline(build_component)
      expect(page).to have_css("form[data-turbo-stream]")
    end

    it "preselects the entry's current lane" do
      expanding = build_stubbed(:notebook_entry, game: game, slug: "expandslug123456", status: "expand")
      render_inline(build_component(notebook_entry: expanding))
      expect(page.find("select option[selected]").value).to eq("expand")
    end

    it "offers every lane as an option" do
      render_inline(build_component)
      expect(page.all("select option").map(&:value)).to eq(NotebookEntry::STATUSES)
    end

    it "labels the select for screen readers without showing a visible label" do
      render_inline(build_component)
      expect(page).to have_css("label.sr-only", text: "Lane")
    end
  end
end
