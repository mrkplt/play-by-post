# typed: true
# frozen_string_literal: true

module Ai
  class Moderation
    module Rules
      # Blocks when the OpenAI Moderation API flagged any category on the prompt.
      # This is the broad net: whatever omni-moderation itself considers a
      # violation (sexual, sexual/minors, violence, ...) blocks the generation,
      # and the flagged category names become the failure reason.
      class FlaggedCategories < Rule
        sig do
          override.params(
            _prompt: String, result: T::Hash[String, T.untyped]
          ).returns(Rule::Outcome)
        end
        def moderate(_prompt, result)
          categories = (result["categories"] || {}).select { |_name, hit| hit }.keys
          return allow if categories.empty?

          block("flagged by moderation: #{categories.sort.join(', ')}")
        end
      end
    end
  end
end
