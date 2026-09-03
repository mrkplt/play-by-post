require "rails_helper"

# Blocks when OpenAI flagged any category, using the flagged category names as
# the reason.
RSpec.describe Ai::Moderation::Rules::FlaggedCategories do
  it "allows when no category is flagged" do
    outcome = described_class.moderate("a knight", "categories" => { "sexual" => false, "violence" => false })
    expect(outcome.moderated?).to be(false)
  end

  it "allows when there is no categories key at all" do
    expect(described_class.moderate("a knight", {}).moderated?).to be(false)
  end

  it "blocks when a category is flagged, listing the flagged names sorted" do
    outcome = described_class.moderate("bad", "categories" => { "violence" => true, "sexual" => true, "hate" => false })

    expect(outcome.moderated?).to be(true)
    expect(outcome.reason).to eq("flagged by moderation: sexual, violence")
  end
end
