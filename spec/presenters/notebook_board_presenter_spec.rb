require "rails_helper"

RSpec.describe NotebookBoardPresenter do
  describe "#entries_by_status" do
    it "groups entries by status" do
      new_entry = build_stubbed(:notebook_entry, status: "new")
      done_entry = build_stubbed(:notebook_entry, status: "done")
      presenter = described_class.new([ new_entry, done_entry ])

      expect(presenter.entries_by_status).to eq(
        "new" => [ new_entry ],
        "done" => [ done_entry ]
      )
    end

    it "is empty for no entries" do
      presenter = described_class.new([])
      expect(presenter.entries_by_status).to eq({})
    end
  end
end
