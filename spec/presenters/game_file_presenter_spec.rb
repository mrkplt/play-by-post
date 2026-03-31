require "rails_helper"

RSpec.describe GameFilePresenter do
  let(:game_file) { build_stubbed(:game_file) }

  subject(:presenter) { described_class.new(game_file) }

  describe "#human_file_size" do
    context "when no file is attached" do
      before { allow(game_file).to receive(:file).and_return(double(attached?: false)) }

      it { expect(presenter.human_file_size).to eq("") }
    end

    context "when a file is attached" do
      before do
        allow(game_file).to receive(:file).and_return(
          double(attached?: true, byte_size: 2_048)
        )
      end

      it "returns a human-readable size" do
        expect(presenter.human_file_size).to eq("2 KB")
      end
    end
  end

  describe "delegation" do
    it "delegates filename to the model" do
      expect(presenter.filename).to eq(game_file.filename)
    end

    it "delegates file_extension to the model" do
      expect(presenter.file_extension).to eq(game_file.file_extension)
    end

    it "delegates image? to the model" do
      allow(game_file).to receive(:image?).and_return(true)
      expect(presenter.image?).to be true
    end
  end
end
