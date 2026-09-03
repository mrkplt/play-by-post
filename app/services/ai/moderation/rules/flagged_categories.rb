# typed: true
# frozen_string_literal: true

# Blocks when the OpenAI Moderation API flagged any category on the prompt. This
# is the broad net: whatever omni-moderation itself considers a violation
# (sexual, sexual/minors, violence, ...) blocks the generation, and the flagged
# category names become the failure reason.
#
# Compact nesting (module Ai::Moderation::Rules::…) so this file introduces no
# `class Moderation` namespace-reopen token — Moderation is a class elsewhere,
# and reopening it here as a class would trip the service-module check.
module Ai::Moderation::Rules::FlaggedCategories
  extend T::Sig

  sig do
    params(_prompt: String, result: T::Hash[String, T.untyped]).returns(Ai::Moderation::Rule::Outcome)
  end
  def self.moderate(_prompt, result)
    categories = (result["categories"] || {}).select { |_name, hit| hit }.keys
    return Ai::Moderation::Rule.allow if categories.empty?

    Ai::Moderation::Rule.block("flagged by moderation: #{categories.sort.join(', ')}")
  end
end
