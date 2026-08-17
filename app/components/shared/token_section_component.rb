# typed: strict

# A profile "tokens" section: one row per game the user belongs to, each offering
# to create a bearer token or — when one exists — revealing the copyable secret
# (via Ui::SecretFieldComponent) and a revoke control. The RSS-feed section and
# the API-token section are the same layout with four values swapped, so they are
# one parameterized component rather than two near-identical forks: the reveal
# label, the create-button label, and the scope posted on create differ; the row
# presenters (GameFeedRowPresenter, ApiTokenRowPresenter) supply the rest through
# a shared interface (name, token?, secret_value, create_path, revoke_path,
# game_id).
class Shared::TokenSectionComponent < ApplicationComponent
  extend T::Sig

  POSITIONS = T.let({ true => :last, false => :middle }.freeze, T::Hash[T::Boolean, Symbol])

  sig { params(rows: T::Array[T.untyped], scope: String, secret_label: String, create_label: String).void }
  def initialize(rows:, scope:, secret_label:, create_label:)
    @rows = T.let(rows, T::Array[T.untyped])
    @scope = T.let(scope, String)
    @secret_label = T.let(secret_label, String)
    @create_label = T.let(create_label, String)
  end

  sig { returns(T::Array[T.untyped]) }
  attr_reader :rows

  sig { returns(String) }
  attr_reader :scope

  sig { returns(String) }
  attr_reader :secret_label

  sig { returns(String) }
  attr_reader :create_label

  sig { params(index: Integer).returns(Symbol) }
  def row_position(index)
    POSITIONS.fetch(index == rows.length - 1)
  end
end
