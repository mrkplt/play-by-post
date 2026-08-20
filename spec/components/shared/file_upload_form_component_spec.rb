require "rails_helper"

RSpec.describe Shared::FileUploadFormComponent, type: :component do
  let(:game_model) { build_stubbed(:game) }
  let(:game) { GamePresenter.new(game_model, policy: instance_double(GamePolicy)) }

  context "without a game_file" do
    subject(:component) { described_class.new(game: game) }

    it "error? returns false" do
      expect(component.error?).to be(false)
    end

    it "error_message returns nil" do
      expect(component.error_message).to be_nil
    end

    it "max_bytes returns the model limit" do
      expect(component.max_bytes).to eq(GameFile::MAX_SIZE)
    end

    it "max_megabytes returns 50" do
      expect(component.max_megabytes).to eq(50)
    end

    it "renders the upload form with the size hint" do
      render_inline(component)
      expect(page).to have_text("Max 50MB")
      expect(page).to have_button("Upload")
    end

    it "wires the file-size Stimulus controller with the max bytes value" do
      render_inline(component)
      expect(page).to have_css("[data-controller='file-size'][data-file-size-max-bytes-value='#{GameFile::MAX_SIZE}']")
    end

    it "does not render an error message" do
      render_inline(component)
      expect(page).not_to have_css("p.bg-error-bg")
    end
  end

  context "with a game_file carrying a size error" do
    let(:game_file) do
      gf = GameFile.new(game: game_model, filename: "big.pdf")
      gf.file.attach(io: StringIO.new("x" * (GameFile::MAX_SIZE + 1)), filename: "big.pdf", content_type: "application/pdf")
      gf.valid?
      GameFilePresenter.new(gf)
    end

    subject(:component) { described_class.new(game: game, game_file: game_file) }

    it "error? returns true" do
      expect(component.error?).to be(true)
    end

    it "error_message returns the size error" do
      expect(component.error_message).to eq("must be less than 50MB")
    end

    it "renders the error message" do
      render_inline(component)
      expect(page).to have_css("p.bg-error-bg", text: "must be less than 50MB")
    end
  end

  context "with a game_file carrying only a base error" do
    let(:game_file) do
      gf = GameFile.new(game: game_model, filename: "x.pdf")
      gf.errors.add(:base, "something went wrong")
      GameFilePresenter.new(gf)
    end

    subject(:component) { described_class.new(game: game, game_file: game_file) }

    it "falls back to the first full message" do
      expect(component.error_message).to eq("something went wrong")
    end
  end
end
