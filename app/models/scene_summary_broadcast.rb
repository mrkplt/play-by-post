# typed: true
# frozen_string_literal: true

# Pushes a finished scene summary to the viewers waiting on the scene page.
#
# When SceneSummaryJob produces (or a GM publishes) a summary, every viewer whose
# visibility class should see it has a pending frame subscribed to
# `[scene, :summary, <class>]`. This replaces that frame, per class, with the
# rendered summary, and drops a "ready" toast into #toast_layer on the same
# streams. A class that must not see the summary (a draft to non-managers, an AI
# summary to hidden-preference viewers) is never broadcast to, so its viewers
# keep waiting — exactly as SceneSummary#visible_to? would gate the page.
class SceneSummaryBroadcast
  extend T::Sig

  READY_TOAST = { message: "Scene summary ready.", variant: :success }.freeze

  sig { params(summary: SceneSummary).void }
  def initialize(summary)
    @summary = summary
  end

  sig { void }
  def call
    SceneSummaryVisibility.classes_for(@summary).each { |klass| broadcast_to(klass) }
  end

  private

  sig { params(klass: Symbol).void }
  def broadcast_to(klass)
    stream = [ scene, :summary, klass ]

    Turbo::StreamsChannel.broadcast_replace_to(
      *stream,
      target: SceneSummaryChannel::PENDING_FRAME_ID,
      renderable: Shared::SceneSummaryComponent.new(summary: presenter_for(klass)),
      layout: false
    )
    Turbo::StreamsChannel.broadcast_replace_to(
      *stream,
      target: "toast_layer",
      renderable: Ui::ToastComponent.new(toasts: [ READY_TOAST ]),
      layout: false
    )
  end

  sig { params(klass: Symbol).returns(SceneSummaryPresenter) }
  def presenter_for(klass)
    SceneSummaryPresenter.for_broadcast(@summary, klass: klass, game: T.must(scene.game))
  end

  sig { returns(Scene) }
  def scene
    T.must(@summary.scene)
  end
end
