require "rails_helper"

RSpec.describe Shared::NotebookLaneSelectComponent, type: :component do
  let(:game) { build_stubbed(:game) }
  let(:game_presenter) { GamePresenter.new(game, policy: instance_double(GamePolicy)) }
  let(:entry) do
    NotebookEntryPresenter.new(build_stubbed(:notebook_entry, game: game, title: "Idea", slug: "abc123def456ghij"))
  end

  def build_component(**overrides)
    described_class.new(**{ game: game_presenter, notebook_entry: entry }.merge(overrides))
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

    it "submits itself on change" do
      render_inline(build_component)
      expect(page.find("select[name='notebook_entry[status]']")["data-action"])
        .to eq("change->lane-select#submit")
    end

    # The controller blurs the select before submitting; without it the move
    # response replaces the element while its dropdown is still open.
    it "drives the change through the lane-select controller, not an inline handler" do
      render_inline(build_component)
      expect(page).to have_css("form[data-controller='lane-select']")
      expect(page.find("select[name='notebook_entry[status]']")["onchange"]).to be_nil
    end

    it "keeps a submit button, without which requestSubmit() does nothing" do
      render_inline(build_component)
      expect(page).to have_css("input[type='submit'].sr-only", visible: :all, count: 1)
    end

    it "drives the move over Turbo on the board" do
      render_inline(build_component)
      expect(page).to have_css("form[data-turbo-stream]")
    end

    # `data-turbo-stream="false"` is still an attribute, so presence alone does
    # not prove the flag survived — assert the value Turbo actually reads.
    it "sets the Turbo Stream flag true, not merely present" do
      expect(build_component.form_data[:turbo_stream]).to be(true)
      render_inline(build_component)
      expect(page.find("form")["data-turbo-stream"]).to eq("true")
    end

    it "states where it was rendered so the controller can pick a response" do
      render_inline(build_component(mode: :standalone))
      expect(page).to have_field("response_mode", type: :hidden, with: "standalone")
    end

    it "states the board mode the same way" do
      render_inline(build_component)
      expect(page).to have_field("response_mode", type: :hidden, with: "board")
    end

    it "gives each entry's select its own id, so rows do not share a label" do
      other = NotebookEntryPresenter.new(
        build_stubbed(:notebook_entry, game: game, title: "Other", slug: "otherslug1234567")
      )
      render_inline(build_component)
      first_id = page.find("select")["id"]
      render_inline(build_component(notebook_entry: other))

      expect(first_id).to eq("notebook_entry_status_#{entry.slug}")
      expect(page.find("select")["id"]).to eq("notebook_entry_status_#{other.slug}")
      expect(page.find("select")["id"]).not_to eq(first_id)
    end

    it "points the label at its own select" do
      render_inline(build_component)
      expect(page.find("label")["for"]).to eq(page.find("select")["id"])
    end

    it "names the entry in the label, so rows are distinguishable" do
      render_inline(build_component)
      expect(page.find("label", visible: :all).text).to eq("Lane for Idea")
    end

    it "drives the move over a Turbo Stream so the board does not navigate" do
      render_inline(build_component)
      expect(page).to have_css("form[data-turbo-stream]")
    end

    it "preselects the entry's current lane" do
      expanding = NotebookEntryPresenter.new(
        build_stubbed(:notebook_entry, game: game, slug: "expandslug123456", status: "expand")
      )
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
