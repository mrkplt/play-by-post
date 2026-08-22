# typed: strict
# frozen_string_literal: true

# The per-viewer visibility of a scene summary, reduced to a small closed set of
# "visibility classes" so a single broadcast can respect it.
#
# A summary is not visible the same way to everyone: a *draft* is visible only to
# a manager (the GM); an *AI-generated* summary is hidden from a viewer whose
# ai_display_preference is "hidden". Polling handled this by recomputing per
# request. A broadcast is one message to many subscribers, so instead we key the
# Turbo stream by which of these classes a viewer belongs to, and broadcast only
# to the classes that should see a given summary. The stream name is signed, so a
# client cannot subscribe to a class it was not served.
#
# This is the SINGLE source of that mapping — the scene page asks `for_viewer` to
# pick the viewer's stream, and SceneSummaryJob asks `classes_for` which streams
# to broadcast to. Both derive from the same facts SceneSummary#visible_to? uses
# (manage?, ai_generated?, viewer hidden?), so the "show" and the "broadcast"
# decisions can never diverge.
module SceneSummaryVisibility
  extend T::Sig

  # A manager (GM) sees everything, including an unpublished draft. A non-manager
  # whose display preference is NOT hidden sees published summaries including AI
  # ones (`plain`); a non-manager whose preference IS hidden sees only non-AI
  # published summaries (`hidden`).
  MANAGER = :manager
  PLAIN = :plain
  HIDDEN = :hidden

  CLASSES = T.let([ MANAGER, PLAIN, HIDDEN ].freeze, T::Array[Symbol])

  # The visibility class a viewer belongs to for a game — the one stream that
  # viewer subscribes to on the scene page. Derives GM-ness from the game (the
  # same question SceneSummaryPolicy#manage? asks) rather than taking a policy or
  # a SceneSummary — building a summary just to ask would back-populate the
  # scene's has_one and make the page think one exists. A nil viewer (an
  # unauthenticated cable socket) is never a manager and has no display
  # preference to hide behind, so it falls into the plain class.
  sig { params(game: Game, viewer: T.nilable(User)).returns(Symbol) }
  def self.for_viewer(game:, viewer:)
    return PLAIN unless viewer
    return MANAGER if game.game_master?(viewer)

    viewer.user_profile&.hidden? ? HIDDEN : PLAIN
  end

  # The visibility classes a summary should be broadcast to — every class whose
  # members are allowed to see it. Mirrors SceneSummary#visible_to? across the
  # class set: a draft reaches only managers; an AI-generated summary reaches
  # managers and plain viewers but never hidden-preference ones; a non-AI
  # published summary reaches all three.
  sig { params(summary: SceneSummary).returns(T::Array[Symbol]) }
  def self.classes_for(summary)
    return [ MANAGER ] if summary.draft?
    return [ MANAGER, PLAIN ] if summary.ai_generated?

    CLASSES
  end
end
