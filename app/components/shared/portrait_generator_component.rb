# typed: strict

# The AI-portrait generation control on the character screen, for the owning
# player. It renders inside its own stable target (TARGET_ID) — the library is
# a separate div. States, driven by the character's newest generation skeleton
# (a presenter passes plain flags/strings — no raw model reaches here):
#
#   - pending: a spinner whose portrait-poll Stimulus controller polls #show on
#     an interval; #show returns a Turbo Stream the controller applies, which
#     replaces this control AND the library (so a finished portrait appears)
#     plus a toast.
#   - failed:  the failure message + the form, so the player can retry.
#   - idle:    just the prompt form (POST `generate_url`).
class Shared::PortraitGeneratorComponent < ApplicationComponent
  extend T::Sig

  TARGET_ID = "character_portrait_generator"
  PENDING_MESSAGE = "Generating your portrait…"

  sig do
    params(
      generate_url: String,
      poll_url: String,
      pending: T::Boolean,
      failure_reason: T.nilable(String)
    ).void
  end
  def initialize(generate_url:, poll_url:, pending:, failure_reason: nil)
    @generate_url = generate_url
    @poll_url = poll_url
    @pending = pending
    @failure_reason = failure_reason
  end

  sig { returns(String) }
  attr_reader :generate_url

  sig { returns(String) }
  attr_reader :poll_url

  sig { returns(T::Boolean) }
  def pending?
    @pending
  end

  sig { returns(T::Boolean) }
  def failed?
    !@failure_reason.nil?
  end

  sig { returns(String) }
  def failure_reason
    @failure_reason.to_s
  end
end
