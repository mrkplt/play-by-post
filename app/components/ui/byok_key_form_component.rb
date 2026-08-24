# typed: strict

# The BYOK (bring-your-own OpenRouter key) settings control — add or delete
# an owner's OpenRouter API key without the plaintext ever reaching the
# server. Three states, driven by whether a keypair/sealed key exists yet (no
# raw model reaches this component — a presenter/controller passes plain
# values):
#
#   1. No keypair yet (#keypair_ready? false): a "Set up encryption" button
#      that POSTs to `generate_url` (Profiles::ByokKeysController#create),
#      which enqueues KeypairGenerationJob and swaps this control to its
#      pending state in place.
#   2. Keypair exists but no key sealed yet (#keypair_ready?, not
#      #key_present?): the paste-a-key form, wired to the `byok-key-seal`
#      Stimulus controller, which encrypts the pasted key client-side
#      (WebCrypto) to `public_key_pem` and submits only the sealed envelope to
#      `seal_url`.
#   3. Key present (#key_present?): NO input at all — a stored key cannot be
#      retrieved, so there is nothing to show or re-paste. Just a line saying a
#      key is saved and a "Delete" button (DELETE to `delete_url`). Deleting
#      tears the whole EncryptedValue (and its keypair) down to the neutral
#      state; adding a key again generates a fresh keypair. There is
#      deliberately no "replace" affordance — replace-with-the-same-keypair is
#      not a real operation.
#
# Between states 1 and 2 there is a transient PENDING moment: "Set up
# encryption" enqueues the async KeypairGenerationJob on the worker, so the
# keypair does not exist the instant the button is clicked. #create responds
# with this component in its `pending` state — a spinner whose `frame-poll`
# Stimulus controller reloads this control's Turbo Frame (GET #show,
# `endpoint_url`) every second until the keypair exists and #show renders the
# state-2 paste form instead. Polling is deterministic — no broadcast to miss,
# no websocket dependency. `pending` is only ever set by #create's Turbo Stream
# response and by #show while the keypair is still absent — it is
# presence-on-page, not a persisted condition.
#
# The whole control renders inside turbo_frame_tag(FRAME_ID) so #create/
# #update/#destroy Turbo Streams and the pending poll all target one frame.
#
# The plaintext key is never sent as a named form field — the Stimulus
# controller clears the paste input before submit, and only the hidden
# envelope fields (populated by WebCrypto) are ever named/submitted.
class Ui::ByokKeyFormComponent < ApplicationComponent
  extend T::Sig

  # The Turbo Frame id the whole control renders inside — every controller
  # Turbo Stream targets it, and the pending state's frame-poll reloads it.
  FRAME_ID = "byok_key_control"

  PENDING_MESSAGE = "Preparing your encryption key…"

  # All four actions (show/create/seal/delete) target the same singleton
  # `profile_byok_key_path` — they differ only by HTTP verb, which
  # button_to/form_with/frame-poll supply — so this takes one endpoint_url.
  sig do
    params(
      key_present: T::Boolean,
      public_key_pem: T.nilable(String),
      endpoint_url: String,
      pending: T::Boolean
    ).void
  end
  def initialize(key_present:, public_key_pem:, endpoint_url:, pending:)
    @key_present = key_present
    @public_key_pem = public_key_pem
    @endpoint_url = endpoint_url
    @pending = pending
  end

  sig { returns(String) }
  def frame_id
    FRAME_ID
  end

  # The card wrapper's classes. Ui::CardComponent's shell is px-3.5 only; this
  # control wants the taller py-3 padding, so it carries its own.
  sig { returns(String) }
  def card_classes
    "bg-card border border-card-border rounded-card px-3.5 py-3"
  end

  sig { returns(String) }
  def heading_classes
    "text-sm text-ink font-bold mb-1"
  end

  sig { returns(T::Boolean) }
  def pending?
    @pending
  end

  sig { returns(String) }
  def pending_message
    PENDING_MESSAGE
  end

  sig { returns(T::Boolean) }
  def key_present?
    @key_present
  end

  sig { returns(T::Boolean) }
  def keypair_ready?
    @public_key_pem.present?
  end

  sig { returns(String) }
  def public_key_pem
    T.must(@public_key_pem)
  end

  sig { returns(String) }
  attr_reader :endpoint_url

  sig { returns(String) }
  def heading
    key_present? ? "OpenRouter key" : "Bring your own OpenRouter key"
  end

  sig { returns(String) }
  def status_text
    key_present? ? "A key is saved. It can't be shown again — delete it to set a new one." : "No key configured yet."
  end
end
