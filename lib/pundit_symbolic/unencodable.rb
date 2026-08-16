# typed: true
# frozen_string_literal: true

module PunditSymbolic
  # Raised when a method body falls outside the boolean-over-leaf-facts subset.
  # A public predicate that cannot be encoded is a finding, not a silent skip:
  # either the encoder is incomplete or the policy violates the "public surface
  # is boolean predicates" convention. Package-level because the encoder and its
  # helpers (PathNaming, CallShapes) all raise it. Carries only the bare reason;
  # the caller that knows which method failed (PolicySource) records that.
  class Unencodable < StandardError
    def initialize(reason)
      super
    end

    def reason = message
  end
end
