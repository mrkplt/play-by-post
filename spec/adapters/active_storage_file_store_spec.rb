# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActiveStorageFileStore do
  subject(:adapter) { described_class.new }

  let(:game_file) { create(:game_file) }
  let(:attachment) { instance_double(ActiveStorage::Attached::One, attach: nil, purge_later: nil) }

  before { allow(game_file).to receive(:file).and_return(attachment) }

  describe "#attach" do
    let(:upload) do
      ActionDispatch::Http::UploadedFile.new(
        tempfile: Tempfile.new("upload"),
        filename: "test.png",
        type: "image/png"
      )
    end

    it "attaches the upload to the game file" do
      adapter.attach(game_file: game_file, upload: upload)
      expect(attachment).to have_received(:attach).with(upload)
    end
  end

  describe "#purge" do
    it "purges the attachment asynchronously" do
      adapter.purge(game_file: game_file)
      expect(attachment).to have_received(:purge_later)
    end
  end
end
