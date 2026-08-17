# typed: false

require "rails_helper"

# Unit coverage for the shared /api index filter object. Exercised against real
# Page relations so the model-supplied scopes (title_matching, created_by)
# resolve; the request-level behaviour specs assert the same filters end to end,
# but these cover the param-parsing edges the controller can't easily reach —
# a malformed `since` and an unrecognised `order` both degrading rather than
# erroring.
RSpec.describe Api::IndexFilters, :db do
  let(:game) { create(:game) }
  let(:gm) { create(:user, :with_profile) }

  def apply(params)
    described_class.new(game.pages, ActionController::Parameters.new(params)).apply.to_a
  end

  it "returns every page, newest-first, with no params" do
    older = Timecop.freeze(2.days.ago) { create(:page, game: game, title: "Older", editor: gm) }
    newer = create(:page, game: game, title: "Newer", editor: gm)

    expect(apply({})).to eq([ newer, older ])
  end

  it "filters to titles containing the term when title is given" do
    dragon = create(:page, game: game, title: "The Red Dragon", editor: gm)
    create(:page, game: game, title: "A Quiet Inn", editor: gm)

    expect(apply(title: "dragon")).to eq([ dragon ])
  end

  it "filters to pages created by the given created_by id" do
    other = create(:user, :with_profile)
    mine = create(:page, game: game, title: "Mine", editor: gm)
    create(:page, game: game, title: "Theirs", editor: other)

    expect(apply(created_by: gm.id.to_s)).to eq([ mine ])
  end

  it "created_by matches on the id value, not merely the presence of the param" do
    create(:page, game: game, title: "Mine", editor: gm)

    # A user id that no version was authored by yields no pages — proving the id
    # itself is the predicate, not just that a created_by param was supplied.
    expect(apply(created_by: "0")).to be_empty
  end

  it "filters to pages the given edited_by id authored any version of" do
    other = create(:user, :with_profile)
    edited = create(:page, game: game, title: "Edited", editor: gm)
    Current.user = other
    edited.update!(body: "touched")
    Current.user = nil
    create(:page, game: game, title: "Untouched", editor: gm)

    expect(apply(edited_by: other.id.to_s)).to eq([ edited ])
  end

  it "edited_by matches on the id value, not merely the presence of the param" do
    create(:page, game: game, title: "Edited", editor: gm)

    expect(apply(edited_by: "0")).to be_empty
  end

  it "orders oldest-first when order=oldest" do
    older = Timecop.freeze(2.days.ago) { create(:page, game: game, title: "Older", editor: gm) }
    newer = create(:page, game: game, title: "Newer", editor: gm)

    expect(apply(order: "oldest")).to eq([ older, newer ])
  end

  it "ignores an unrecognised order and falls back to newest-first" do
    older = Timecop.freeze(2.days.ago) { create(:page, game: game, title: "Older", editor: gm) }
    newer = create(:page, game: game, title: "Newer", editor: gm)

    expect(apply(order: "sideways")).to eq([ newer, older ])
  end

  it "ignores a `since` that is not a valid timestamp" do
    page = create(:page, game: game, title: "Kept", editor: gm)

    expect(apply(since: "not-a-date")).to include(page)
  end

  it "applies a valid `since` floor" do
    old_page = Timecop.freeze(3.days.ago) { create(:page, game: game, title: "Old", editor: gm) }
    new_page = create(:page, game: game, title: "New", editor: gm)

    result = apply(since: 1.day.ago.iso8601)
    expect(result).to include(new_page)
    expect(result).not_to include(old_page)
  end

  # `since` is parsed with Time.zone.iso8601, which accepts a bare date (midnight
  # in the app zone); plain Time.iso8601 rejects a date without a time, so a
  # date-only floor exercises the zone-aware parser specifically. Freezing the
  # clock keeps the two records on known sides of a same-day midnight boundary.
  it "accepts a date-only `since` and floors it at midnight in the app zone" do
    Time.use_zone("UTC") do
      before_midnight = Timecop.freeze(Time.utc(2025, 12, 31, 23, 0, 0)) do
        create(:page, game: game, title: "NYE", editor: gm)
      end
      after_midnight = Timecop.freeze(Time.utc(2026, 1, 1, 1, 0, 0)) do
        create(:page, game: game, title: "NYD", editor: gm)
      end

      result = apply(since: "2026-01-01")
      expect(result).to include(after_midnight)
      expect(result).not_to include(before_midnight)
    end
  end

  it "ignores blank params rather than filtering on an empty string" do
    page = create(:page, game: game, title: "Kept", editor: gm)

    expect(apply(title: "", created_by: "", edited_by: "", since: "")).to include(page)
  end
end
