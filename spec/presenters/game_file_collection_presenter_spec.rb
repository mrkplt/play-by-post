require "rails_helper"

RSpec.describe GameFileCollectionPresenter do
  describe "#empty?" do
    it "is true when the relation is empty", :db do
      presenter = described_class.new(GameFile.none)
      expect(presenter.empty?).to be(true)
    end

    it "is false when the relation has rows", :db do
      create(:game_file)
      presenter = described_class.new(GameFile.all)
      expect(presenter.empty?).to be(false)
    end
  end

  describe "#models" do
    it "returns the underlying records as a plain array", :db do
      file_1 = create(:game_file)
      file_2 = create(:game_file)
      presenter = described_class.new(GameFile.where(id: [ file_1.id, file_2.id ]).order(:id))

      expect(presenter.models).to eq([ file_1, file_2 ])
    end
  end
end
