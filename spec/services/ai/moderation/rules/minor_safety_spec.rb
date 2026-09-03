require "rails_helper"

# Zero-tolerance on the sexual/minors score: any non-zero score blocks,
# independently of OpenAI's overall flagged threshold.
RSpec.describe Ai::Moderation::Rules::MinorSafety do
  it "allows when the sexual/minors score is zero" do
    outcome = described_class.moderate("a knight", "category_scores" => { "sexual/minors" => 0.0 })
    expect(outcome.moderated?).to be(false)
  end

  it "allows when the score is absent" do
    expect(described_class.moderate("a knight", {}).moderated?).to be(false)
    expect(described_class.moderate("a knight", "category_scores" => {}).moderated?).to be(false)
  end

  it "blocks on any non-zero score, even one below OpenAI's own flag threshold" do
    outcome = described_class.moderate("bad", "category_scores" => { "sexual/minors" => 0.001 })

    expect(outcome.moderated?).to be(true)
    expect(outcome.reason).to include("sexual/minors")
  end
end
