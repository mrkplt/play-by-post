# typed: true
# frozen_string_literal: true

module Ai
  class Moderation
    # The shared surface for a moderation rule. Each concrete rule is a MODULE
    # under Ai::Moderation::Rules with its own `moderate(prompt, result)`; it is
    # individually responsible for enforcing one policy given the prompt and the
    # OpenAI Moderation API result, and returns an Outcome (moderated? + reason).
    #
    # Rules are stateless process objects, so they are modules, not classes (the
    # service-module convention) — there is nothing to instantiate. Ai::Moderation
    # runs every rule module and aggregates; adding a rule is adding a module
    # under Rules, discovered by reflection (Rules.constants), no registry.
    #
    # This module provides the block/allow Outcome builders the rules call, and
    # the Outcome value object. There is no abstract `moderate` here: a rule
    # module simply defines its own `moderate`, and Ai::Moderation only calls
    # modules that respond to it.
    module Rule
      extend T::Sig

      # A rule's result: whether it moderated (blocked) the content, and — when
      # it did — the human-readable reason for the alert/notice.
      class Outcome < T::Struct
        extend T::Sig

        const :moderated, T::Boolean
        const :reason, String, default: ""

        sig { returns(T::Boolean) }
        def moderated?
          moderated
        end
      end

      class << self
        extend T::Sig

        sig { params(reason: String).returns(Outcome) }
        def block(reason)
          Outcome.new(moderated: true, reason: reason)
        end

        sig { returns(Outcome) }
        def allow
          Outcome.new(moderated: false)
        end
      end
    end
  end
end
