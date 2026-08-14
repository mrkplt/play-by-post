require "rails_helper"

RSpec.describe Shared::NotebookLaneComponent, type: :component do
  let(:game) { build_stubbed(:game) }
  let(:game_presenter) { GamePresenter.new(game, policy: instance_double(GamePolicy)) }

  def entry(title:, slug:, status: "new")
    NotebookEntryPresenter.new(build_stubbed(:notebook_entry, game: game, status: status, title: title, slug: slug))
  end

  def build_component(**overrides)
    described_class.new(**{ game: game_presenter, status: "new", entries: [] }.merge(overrides))
  end

  describe ".label_for" do
    Shared::NotebookLaneComponent::PRESENTATION.each do |status, presentation|
      it "labels #{status.inspect} as #{presentation[:label].inspect}" do
        expect(described_class.label_for(status)).to eq(presentation[:label])
      end
    end

    it "covers every status the model allows" do
      expect(described_class::PRESENTATION.keys).to match_array(NotebookEntry::STATUSES)
    end

    it "raises on a status it has no label for, rather than rendering blank" do
      expect { described_class.label_for("nonsense") }.to raise_error(KeyError)
    end
  end

  describe ".empty_text_for" do
    it "words the discard lane's emptiness as expected, not as an oversight" do
      expect(described_class.empty_text_for("discard")).to eq(described_class::DISCARD_EMPTY_TEXT)
    end

    it "uses the generic empty text for every other lane" do
      %w[new expand done].each do |status|
        expect(described_class.empty_text_for(status)).to eq(described_class::EMPTY_TEXT)
      end
    end
  end

  describe "#dom_id" do
    it "matches the board column id the move response targets" do
      expect(build_component(status: "expand").dom_id).to eq("notebook_column_expand")
      expect(build_component(status: "expand").dom_id)
        .to eq(Shared::NotebookBoardComponent.column_id("expand"))
    end
  end

  describe "collapsing" do
    it "renders as a plain labelled section by default" do
      render_inline(build_component())
      expect(page).to have_no_css("details")
      expect(page).to have_text("New")
    end

    it "renders behind a disclosure when one is configured" do
      render_inline(build_component(status: "discard"))
      expect(page).to have_css("details summary", text: "Show discarded")
    end

    it "puts the discard lane behind a disclosure without being told to" do
      render_inline(build_component(status: "discard"))
      expect(page).to have_css("details")
    end

    it "starts closed when the disclosure is :collapsed" do
      render_inline(build_component(disclosure: :collapsed))
      expect(page).to have_no_css("details[open]")
    end

    it "starts open when the disclosure is :expanded" do
      render_inline(build_component(disclosure: :expanded))
      expect(page).to have_css("details[open]")
    end

    it "renders no disclosure at all when :none" do
      render_inline(build_component(disclosure: :none))
      expect(page).to have_no_css("details")
    end

    it "keeps the move target id behind a disclosure" do
      render_inline(build_component(status: "discard", disclosure: :collapsed))
      expect(page).to have_css("#notebook_column_discard", visible: :all)
    end

    it "renders every disclosure state the component declares" do
      described_class::DISCLOSURES.each do |state|
        expect { render_inline(build_component(disclosure: state)) }.not_to raise_error
      end
    end

    it "resolves :default to whatever the status normally does" do
      expect(build_component(status: "discard").disclosure).to eq(:collapsed)
      expect(build_component(status: "new").disclosure).to eq(:none)
    end

    it "lets a caller override the status default" do
      expect(build_component(status: "discard", disclosure: :expanded).disclosure).to eq(:expanded)
    end

    it "puts the discard lane behind a closed disclosure on the board" do
      expect(Shared::NotebookLaneComponent.disclosure_for("discard")).to eq(:collapsed)
    end

    it "leaves the working lanes always visible" do
      %w[new expand done].each do |status|
        expect(Shared::NotebookLaneComponent.disclosure_for(status)).to eq(:none)
      end
    end
  end

  describe "rendering" do
    it "wraps the lane in the id the move response replaces" do
      render_inline(build_component(status: "done"))
      expect(page).to have_css("#notebook_column_done")
    end

    it "lists each entry's title as a link to its edit screen" do
      first = entry(title: "First", slug: "firstslug1234567")
      render_inline(build_component(entries: [ first ]))

      expect(page).to have_link(
        "First",
        href: Rails.application.routes.url_helpers.edit_game_notebook_entry_path(game, first)
      )
    end

    it "carries a lane picker per entry" do
      entries = [ entry(title: "First", slug: "firstslug1234567"), entry(title: "Second", slug: "secondslug123456") ]
      render_inline(build_component(entries: entries))
      expect(page).to have_css("select[name='notebook_entry[status]']", count: 2)
    end

    it "gives every row's picker a distinct id, so labels do not collide" do
      entries = [ entry(title: "First", slug: "firstslug1234567"), entry(title: "Second", slug: "secondslug123456") ]
      render_inline(build_component(entries: entries))

      ids = page.all("select").map { |select| select["id"] }
      expect(ids.uniq.size).to eq(2)
      expect(page.all("label", visible: :all).map { |l| l["for"] }).to eq(ids)
    end

    it "shows the empty placeholder when the lane has no entries" do
      render_inline(build_component)
      expect(page).to have_text(described_class::EMPTY_TEXT)
    end

    it "shows the discard wording when an empty lane is the discard lane" do
      render_inline(build_component(status: "discard"))
      expect(page).to have_text(described_class::DISCARD_EMPTY_TEXT)
    end

    it "does not render entry bodies" do
      with_body = entry(title: "Titled", slug: "bodyslug12345678")
      allow(with_body).to receive(:body).and_return("Body text stays off the board.")
      render_inline(build_component(entries: [ with_body ]))

      expect(page).to have_text("Titled")
      expect(page).to have_no_text("Body text stays off the board.")
    end
  end
end
