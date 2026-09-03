# typed: true
# frozen_string_literal: true

# Zero-tolerance rule for the sexual/minors signal: blocks on any non-zero
# category score, independently of whether OpenAI's own overall `flagged`
# crossed its threshold. Deliberately stricter than the broad FlaggedCategories
# rule — the worst category gets its own hair-trigger.
#
# omni-moderation's sexual/minors category is text-only, which is exactly why
# this runs on the (text) prompt pre-generation.
#
# Compact nesting so this file introduces no `class Moderation` token (see
# FlaggedCategories).
module Ai::Moderation::Rules::MinorSafety
  extend T::Sig

  CATEGORY = "sexual/minors"

  sig do
    params(_prompt: String, result: T::Hash[String, T.untyped]).returns(Ai::Moderation::Rule::Outcome)
  end
  def self.moderate(_prompt, result)
    score = result.dig("category_scores", CATEGORY).to_f
    return Ai::Moderation::Rule.allow unless score.positive?

    Ai::Moderation::Rule.block("blocked on #{CATEGORY} (score #{score})")
  end
end
