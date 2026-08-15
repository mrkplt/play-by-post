require "rails_helper"

RSpec.describe SaveOutcome do
  def outcome(saved:) = described_class.new(saved: saved, confirmation: "Saved it.", failure: "Did not save it.")

  describe "a successful save" do
    it "reports itself saved" do
      expect(outcome(saved: true).saved?).to be(true)
    end

    it "carries the confirmation" do
      expect(outcome(saved: true).message).to eq("Saved it.")
    end

    it "answers ok" do
      expect(outcome(saved: true).status).to eq(:ok)
    end

    it "announces under notice" do
      flash = { now: {} }
      def flash.now = self[:now]

      outcome(saved: true).announce_to(flash)

      expect(flash.now).to eq({ notice: "Saved it." })
    end
  end

  describe "a failed save" do
    it "reports itself not saved" do
      expect(outcome(saved: false).saved?).to be(false)
    end

    it "carries the failure message" do
      expect(outcome(saved: false).message).to eq("Did not save it.")
    end

    it "answers unprocessable" do
      expect(outcome(saved: false).status).to eq(:unprocessable_content)
    end

    it "announces under alert" do
      flash = { now: {} }
      def flash.now = self[:now]

      outcome(saved: false).announce_to(flash)

      expect(flash.now).to eq({ alert: "Did not save it." })
    end
  end

  describe ".for" do
    it "builds the confirmation from the subject" do
      expect(described_class.for(true, "page").message).to eq("Page updated.")
    end

    it "builds the failure from the subject" do
      expect(described_class.for(false, "page").message).to eq("Could not save the page.")
    end

    it "capitalizes only the confirmation's leading word" do
      expect(described_class.for(true, "entry").message).to eq("Entry updated.")
    end

    it "leaves the subject lowercase mid-sentence" do
      expect(described_class.for(false, "entry").message).to eq("Could not save the entry.")
    end

    it "carries the saved state through" do
      expect(described_class.for(true, "page").saved?).to be(true)
      expect(described_class.for(false, "page").saved?).to be(false)
    end
  end
end
