# typed: strict
# frozen_string_literal: true

# The Turbo Stream every in-place mutation answers with: swap the flash into the
# always-present #toast_layer so a confirmation (or error) appears without a
# full-page reload. Actions that also have an on-page control to refresh prepend
# their own control replace(s); a fire-and-forget action answers with just this.
#
# A plain module included directly (not an ActiveSupport::Concern, and not under
# app/**/concerns/ — this project's convention is explicit that we do not use
# Rails "concerns"). `requires_ancestor ApplicationController` lets Sorbet
# resolve turbo_stream/flash/helpers without a per-method T.bind.
#
# flash.now, never flash: an in-place response is not a navigation, so a
# persisted flash would leak onto the next full page load.
module InPlaceRender
  extend T::Sig
  extend T::Helpers

  requires_ancestor { ApplicationController }

  # The stable, always-rendered toast target (Ui::ToastComponent). One constant
  # so a caller assembling a multi-stream response cannot mistype it.
  TOAST_TARGET = "toast_layer"

  private

  # Set the response's notice/alert (whichever is present) in one call, so an
  # in-place action does not repeat `flash.now` per key. flash.now, never flash.
  sig { params(notice: T.nilable(String), alert: T.nilable(String)).void }
  def flash_now(notice: nil, alert: nil)
    { notice: notice, alert: alert }.compact.each { |key, message| flash.now[key] = message }
  end

  # The toast stream built from the current flash — call after setting the flash.
  sig { returns(String) }
  def toast_stream
    helpers.turbo_stream.replace(TOAST_TARGET, Ui::ToastComponent.new(toasts: FlashPresenter.new(flash).toasts))
  end

  # Answer a Turbo client with a stream (the block, or the default template when
  # no block is given) and a non-Turbo client with a redirect to `fallback` — the
  # respond_to/html-fallback shape a mutation that stays on-page repeats. Keeps
  # the two-format block out of the action so the action stays under the
  # statement ceiling.
  sig { params(fallback: String, alert: T.nilable(String), block: T.proc.void).void }
  def turbo_or_redirect(fallback:, alert: nil, &block)
    respond_to do |format|
      format.turbo_stream(&block)
      format.html { redirect_to(fallback, alert: alert) }
    end
  end

  # Re-render the profile's per-game control-plane section (#game_controls) — the
  # in-place answer for a mutation whose effect shows there (API tokens, AI
  # funding). Same source (UserPresenter) the profile renders from, so the swap
  # cannot disagree with a cold load. Mirrors ByokKeyStreams#game_controls.
  sig { params(user: User).returns(String) }
  def game_controls_stream(user)
    helpers.turbo_stream.replace(
      "game_controls",
      partial: "profiles/game_controls",
      locals: { user_presenter: UserPresenter.new(user, helpers: helpers) }
    )
  end
end
