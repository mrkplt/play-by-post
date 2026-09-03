# typed: true
# frozen_string_literal: true

module Ai
  class Moderation
    module Rules
      # Zero-tolerance rule for the sexual/minors signal: blocks on any non-zero
      # category score, independently of whether OpenAI's own overall `flagged`
      # crossed its threshold. This is deliberately stricter than the broad
      # FlaggedCategories rule — the worst category gets its own hair-trigger.
      #
      # omni-moderation's sexual/minors category is text-only, which is exactly
      # why this runs on the (text) prompt pre-generation.
      class MinorSafety < Rule
        CATEGORY = "sexual/minors"

        sig do
          override.params(
            _prompt: String, result: T::Hash[String, T.untyped]
          ).returns(Rule::Outcome)
        end
        def moderate(_prompt, result)
          score = result.dig("category_scores", CATEGORY).to_f
          return allow unless score.positive?

          block("blocked on #{CATEGORY} (score #{score})")
        end
      end
    end
  end
end
