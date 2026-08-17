# typed: strict

# The read view of a single historical version — timestamp, editor, then the
# version's title and body in a card. Shared across every versioned record: page
# and notebook-entry version presenters expose the same interface
# (created_at_timestamp, formatted_created_at, editor_name, title, body), so this
# is one component parameterized by the presenter rather than a per-model fork.
# Keeps the styled markup out of the *_versions/show templates.
class Shared::VersionDetailComponent < ApplicationComponent
  extend T::Sig

  sig { params(version: T.untyped).void }
  def initialize(version:)
    @version = T.let(version, T.untyped)
  end

  sig { returns(T.untyped) }
  attr_reader :version
end
