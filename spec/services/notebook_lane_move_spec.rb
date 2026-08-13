require "rails_helper"

RSpec.describe NotebookLaneMove do
  def build_params(hash)
    ActionController::Parameters.new(hash)
  end

  describe "#attributes" do
    it "permits a status naming a known lane" do
      move = described_class.new(build_params(notebook_entry: { status: "expand" }))

      expect(move.attributes[:status]).to eq("expand")
    end

    it "permits every known lane" do
      NotebookEntry::STATUSES.each do |status|
        move = described_class.new(build_params(notebook_entry: { status: status }))

        expect(move.attributes[:status]).to eq(status)
      end
    end

    # The guard exists so an unknown lane never reaches the model.
    it "rejects a status outside the known lanes" do
      move = described_class.new(build_params(notebook_entry: { status: "nonsense" }))

      expect { move.attributes }.to raise_error(ActionController::BadRequest, /invalid status/)
    end

    it "rejects a missing status" do
      move = described_class.new(build_params(notebook_entry: { title: "x" }))

      expect { move.attributes }.to raise_error(ActionController::BadRequest, /invalid status/)
    end

    it "raises when the notebook_entry key is absent entirely" do
      move = described_class.new(build_params(other: "x"))

      expect { move.attributes }.to raise_error(ActionController::ParameterMissing)
    end

    it "drops any attribute other than status" do
      move = described_class.new(build_params(notebook_entry: { status: "done", title: "Injected" }))

      expect(move.attributes.keys).to contain_exactly("status")
    end
  end

  describe "#standalone?" do
    it "is true when the picker reports it was rendered off the board" do
      move = described_class.new(build_params(response_mode: "standalone"))

      expect(move.standalone?).to be(true)
    end

    it "is false for the board, which consumes the lane-swapping stream" do
      move = described_class.new(build_params(response_mode: "board"))

      expect(move.standalone?).to be(false)
    end

    it "is false when no response mode was submitted" do
      expect(described_class.new(build_params({})).standalone?).to be(false)
    end
  end
end
