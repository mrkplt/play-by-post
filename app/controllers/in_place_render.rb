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

  # The toast stream built from the current flash — call after setting
  # flash.now[:notice]/[:alert].
  sig { returns(String) }
  def toast_stream
    helpers.turbo_stream.replace(TOAST_TARGET, Ui::ToastComponent.new(toasts: FlashPresenter.new(flash).toasts))
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
