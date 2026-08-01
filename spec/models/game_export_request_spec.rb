require "rails_helper"

RSpec.describe GameExportRequest, type: :model do
  let(:user) { create(:user, :with_profile) }
  let(:game) { create(:game) }

  def receipt(succeeded_at:, game: nil, with_archive: true)
    request = create(:game_export_request, user: user, game: game, succeeded_at: succeeded_at)
    request.archive.attach(io: StringIO.new("zip"), filename: "e.zip", content_type: "application/zip") if with_archive
    request
  end

  describe ".valid_receipt_for" do
    it "returns the first candidate whose archive is attached" do
      without = build_stubbed(:game_export_request)
      with = build_stubbed(:game_export_request)
      allow(without).to receive(:archive).and_return(double(attached?: false))
      allow(with).to receive(:archive).and_return(double(attached?: true))
      relation = double
      allow(relation).to receive(:where).and_return(relation)
      allow(relation).to receive(:order).and_return([ without, with ])
      allow(described_class).to receive(:where).and_return(relation)

      expect(described_class.valid_receipt_for(user, game)).to eq(with)
    end

    it "returns nil when the last success is outside the window" do
      receipt(succeeded_at: 25.hours.ago, game: game)
      expect(described_class.valid_receipt_for(user, game)).to be_nil
    end

    it "ignores requests that never succeeded" do
      create(:game_export_request, user: user, game: game, succeeded_at: nil)
      expect(described_class.valid_receipt_for(user, game)).to be_nil
    end

    it "ignores a succeeded request whose archive is no longer attached" do
      receipt(succeeded_at: 1.hour.ago, game: game, with_archive: false)
      expect(described_class.valid_receipt_for(user, game)).to be_nil
    end

    it "orders candidates by most recent success", db: true do
      # The winner (most recent succeeded_at) sits in the MIDDLE by id, so
      # neither an id-asc nor id-desc scan returns it — only ordering by
      # succeeded_at desc does. This kills a dropped `.order(succeeded_at: :desc)`.
      receipt(succeeded_at: 10.hours.ago, game: game)          # lowest id
      newest = receipt(succeeded_at: 1.hour.ago, game: game)   # middle id
      receipt(succeeded_at: 5.hours.ago, game: game)           # highest id

      expect(described_class.valid_receipt_for(user, game)).to eq(newest)
    end

    it "scopes to the given game (all-games uses nil)" do
      receipt(succeeded_at: 1.hour.ago, game: game)
      expect(described_class.valid_receipt_for(user, nil)).to be_nil
    end
  end

  describe "#receipt?" do
    it "is true when succeeded and archive attached" do
      expect(receipt(succeeded_at: 1.hour.ago, game: game).receipt?).to be(true)
    end

    it "is false without succeeded_at" do
      request = create(:game_export_request, user: user, game: game, succeeded_at: nil)
      request.archive.attach(io: StringIO.new("zip"), filename: "e.zip", content_type: "application/zip")
      expect(request.receipt?).to be(false)
    end

    it "is false without an archive" do
      expect(receipt(succeeded_at: 1.hour.ago, game: game, with_archive: false).receipt?).to be(false)
    end
  end

  describe "#mark_succeeded!" do
    it "sets succeeded_at to now" do
      request = build(:game_export_request, user: user, game: game, succeeded_at: nil)
      freeze = Time.utc(2026, 7, 30, 12, 0, 0)

      Timecop.freeze(freeze) { request.mark_succeeded! }

      expect(request.succeeded_at).to be_within(1.second).of(freeze)
    end
  end
end
