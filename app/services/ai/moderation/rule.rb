# typed: true
# frozen_string_literal: true

module Ai
  class Moderation
    # One moderation rule. Each concrete subclass is individually responsible for
    # enforcing a single rule, given the prompt and the OpenAI Moderation API
    # result, and returns an Outcome (moderated? + a failure reason).
    #
    # Ai::Moderation instantiates every subclass (Rule.descendants) and runs them
    # all; if any is moderated, the request is blocked and every failing reason is
    # collected for the alert and the user-facing violation notice. Adding a new
    # rule is adding a subclass — no registry to edit.
    #
    # The base #moderate is abstract: it raises, so a subclass that forgets to
    # implement it fails loudly rather than silently passing content.
    class Rule
      extend T::Sig
      extend T::Helpers
      abstract!

      # A rule's result: whether it moderated (blocked) the content, and — when
      # it did — the human-readable reason for the alert/notice. reason is empty
      # when not moderated.
      class Outcome < T::Struct
        extend T::Sig

        const :moderated, T::Boolean
        const :reason, String, default: ""

        sig { returns(T::Boolean) }
        def moderated?
          moderated
        end
      end

      # Enforce this rule against the prompt and the OpenAI moderation result.
      # `result` is the parsed first `results` entry from the Moderation API
      # (a Hash with "flagged"/"categories"/"category_scores"), or an empty Hash
      # when the API returned nothing usable.
      sig do
        abstract.params(
          _prompt: String, _result: T::Hash[String, T.untyped]
        ).returns(Outcome)
      end
      def moderate(_prompt, _result); end

      # Convenience builders so subclasses read declaratively.
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
