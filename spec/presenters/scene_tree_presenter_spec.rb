require "rails_helper"

RSpec.describe SceneTreePresenter do
  describe "#empty?" do
    it "is true for an empty tree" do
      expect(described_class.new([]).empty?).to be(true)
    end

    it "is false when there is at least one root node" do
      node = { scene: build_stubbed(:scene), children: [] }
      expect(described_class.new([ node ]).empty?).to be(false)
    end
  end

  describe "#trees" do
    it "returns the wrapped node array unchanged" do
      node = { scene: build_stubbed(:scene), children: [] }
      expect(described_class.new([ node ]).trees).to eq([ node ])
    end
  end
end
