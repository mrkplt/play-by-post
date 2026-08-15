# typed: strict
# frozen_string_literal: true

# Answers a save that keeps the writer on the form. Turbo clients get a stream
# that re-renders the form and the toast in place; anything else keeps the old
# round trip, forwarding on success and re-rendering the form on failure.
#
# Pages and notebook entries both edit long-form markdown and both want this,
# so it lives here rather than as a trio of near-identical private methods on
# each controller.
class InPlaceSave
  extend T::Sig

  sig { params(controller: T.untyped, outcome: SaveOutcome, forward_to: String).void }
  def initialize(controller, outcome:, forward_to:)
    @controller = controller
    @outcome = outcome
    @forward_to = forward_to
  end

  sig { void }
  def respond
    @controller.respond_to do |format|
      format.turbo_stream { stream }
      format.html { forward }
    end
  end

  private

  # flash.now, not flash: the writer stays put, so the message belongs to this
  # response rather than a navigation that never happens.
  sig { void }
  def stream
    @outcome.announce_to(@controller.flash)
    @controller.render :update, status: @outcome.status
  end

  sig { void }
  def forward
    return @controller.redirect_to(@forward_to, notice: @outcome.message) if @outcome.saved?

    @controller.render :edit, status: @outcome.status
  end
end
