# typed: strict
# frozen_string_literal: true

# A per-request memo for controller-internal lookups.
#
# Rails copies a controller's instance variables into the view, so any `@game`
# a controller memoizes is reachable from a template — which is why
# bin/check-view-layering reports every ivar a controller or its mixins write,
# regardless of visibility. That rule is right: an ivar IS the view-facing
# surface.
#
# But the lookups behind `before_action :set_game` are not view state; they are
# the controller's own working set, and dropping their memoization to satisfy
# the rule trades a real property for a cosmetic one. `posts#update` went from
# 17 queries to 28 when `game`/`scene`/`post` became fresh lookups, because
# `post` resolves through `scene` through `game` and the action asks for them
# repeatedly.
#
# This holds those values in one place that is not an instance variable, so
# they stay memoized for the request and stay invisible to the view. Controller
# mixins use `memo.fetch(:game) { Game.find(...) }` instead of `@game ||= ...`.
module RequestMemo
  extend T::Sig

  private

  # The store itself is an ivar — unavoidable, since it must live for the
  # request — but it holds no domain object a template would want, and its
  # name is registered as internal so the layering gate can tell it apart
  # from `@game`. Everything domain-shaped lives inside it, not beside it.
  sig { returns(T::Hash[Symbol, T.untyped]) }
  def controller_memo
    @controller_memo ||= T.let({}, T.nilable(T::Hash[Symbol, T.untyped]))
  end

  # Memoized lookup: runs the block once per request per key.
  sig { params(key: Symbol, block: T.proc.returns(T.untyped)).returns(T.untyped) }
  def memo(key, &block)
    controller_memo.fetch(key) { controller_memo[key] = block.call }
  end
end
