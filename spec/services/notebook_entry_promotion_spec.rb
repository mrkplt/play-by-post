require "rails_helper"

RSpec.describe NotebookEntryPromotion, db: true do
  let(:game) { create(:game) }

  describe "#call" do
    it "creates a page from the entry and links it back" do
      entry = create(:notebook_entry, game: game, title: "Ruined Keep", body: "Notes.", status: "expand")

      page = described_class.new(entry).call

      expect(page.title).to eq("Ruined Keep")
      expect(page.body).to eq("Notes.")
      expect(page.game).to eq(game)
      expect(entry.reload.promoted_page).to eq(page)
      expect(entry.status).to eq("done")
    end

    # The guard that makes this a unit rather than two controller lines: a
    # second promote must not produce a second page.
    it "returns the existing page and creates nothing when already promoted" do
      entry = create(:notebook_entry, game: game, title: "Ruined Keep", body: "Notes.")
      first = described_class.new(entry).call

      expect {
        expect(described_class.new(entry.reload).call).to eq(first)
      }.not_to change(Page, :count)
    end

    it "leaves the entry's status alone when it was already promoted" do
      entry = create(:notebook_entry, game: game, status: "expand")
      described_class.new(entry).call
      entry.reload.update!(status: "expand")

      described_class.new(entry.reload).call

      expect(entry.reload.status).to eq("expand")
    end
  end
end
