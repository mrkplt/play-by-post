# typed: strict

# The recurring "avatar + primary label + secondary label" identity cluster.
# Purely presentational, but it owns its own CSS: callers pass a name, the two
# label strings, and a Config bundle of domain/state facts (orientation, colour
# variant, size, avatar tone/size, crown/active) — and the Config decides every
# class. No class strings cross the boundary.
#
# The secondary label may be a plain String (escaped) or an already-safe
# SafeBuffer, so a caller can pass a semantic element (e.g. a <time> built with
# content_tag) and have it render as markup rather than escaped text.
#
# Three domains render it: a post's floated author byline (stacked), a roster
# row, and the nav drawer's profile chip (both inline). Per-site extras that are
# not part of the cluster — a trailing badge/action, a wrapping profile link,
# the row's own divider/padding — stay with the caller; this renders the
# cluster, not the container.
class Ui::IdentityBlockComponent < ApplicationComponent
  extend T::Sig

  sig do
    params(
      name: String,
      primary: String,
      secondary: T.any(String, ActiveSupport::SafeBuffer),
      config: Config
    ).void
  end
  def initialize(name:, primary:, secondary:, config: Config.new)
    config.validate!
    @name = name
    @primary = primary
    @secondary = secondary
    @config = config
  end

  sig { returns(String) }
  attr_reader :name

  sig { returns(String) }
  attr_reader :primary

  sig { returns(T.any(String, ActiveSupport::SafeBuffer)) }
  attr_reader :secondary

  sig { returns(Config) }
  attr_reader :config

  sig { returns(T::Boolean) }
  def crown?
    config.crown
  end
end
