# typed: strict

# One RSS-feed scope row: an account-level ("All games") scope or a single game.
# Takes derived, presentation-ready data — never a raw RssToken/Game plus logic.
# The presenter decides the label, the feed URL (present only when a token
# exists), and the form paths/params; this component owns the markup. Reusable
# on the profile now and an in-game location later.
class Shared::RssTokenComponent < ApplicationComponent
  extend T::Sig

  ACTION_CLASSES = T.let(
    "text-[11px] font-bold text-accent bg-transparent border-0 cursor-pointer p-0",
    String
  )

  DANGER_CLASSES = T.let(
    "text-[11px] font-bold text-danger bg-transparent border-0 cursor-pointer p-0",
    String
  )

  sig do
    params(
      scope_label: String,
      feed_url: T.nilable(String),
      form_path: String,
      revoke_path: String,
      scope_param: T::Hash[Symbol, T.untyped],
      last: T::Boolean
    ).void
  end
  def initialize(scope_label:, feed_url:, form_path:, revoke_path:, scope_param: {}, last: false)
    @scope_label = scope_label
    @feed_url = feed_url
    @form_path = form_path
    @revoke_path = revoke_path
    @scope_param = scope_param
    @last = last
  end

  sig { returns(String) }
  attr_reader :scope_label

  sig { returns(String) }
  attr_reader :form_path

  sig { returns(String) }
  attr_reader :revoke_path

  sig { returns(T::Hash[Symbol, T.untyped]) }
  attr_reader :scope_param

  sig { returns(T::Boolean) }
  def token_present?
    @feed_url.present?
  end

  sig { returns(String) }
  def feed_url
    @feed_url.to_s
  end

  sig { returns(String) }
  def action_label
    token_present? ? "Rotate" : "Generate"
  end

  sig { returns(T::Boolean) }
  def divide?
    !@last
  end

  sig { returns(T::Hash[Symbol, T.untyped]) }
  def rotate_data
    return {} unless token_present?

    { confirm: "Rotating this token will invalidate its existing feed URL. Continue?" }
  end
end
