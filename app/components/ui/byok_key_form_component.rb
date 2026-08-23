# typed: strict

# The BYOK (bring-your-own OpenRouter key) settings control — add or delete
# an owner's OpenRouter API key without the plaintext ever reaching the
# server. Three states, driven by whether a keypair/sealed key exists yet (no
# raw model reaches this component — a presenter/controller passes plain
# values):
#
#   1. No keypair yet (#keypair_ready? false): a "Set up encryption" button
#      that POSTs to `generate_url` (Profiles::ByokKeysController#create),
#      which enqueues KeypairGenerationJob and redirects back here once the
#      keypair exists.
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
# keypair does not exist the instant the button is clicked. Rather than a
# full-page redirect that races the worker (and re-renders the button, not the
# form), #create responds with this component in its `pending` state — a spinner
# frame (Shared::AsyncPendingComponent) subscribed to `[owner, :byok_keypair]`.
# When the worker finishes it broadcasts the state-2 paste form into that same
# frame (KeypairReadyBroadcast), so the form appears in place with no reload.
# `pending` is only ever set by that Turbo Stream response, never on a cold page
# load — it is presence-on-page, not a persisted condition (a mid-generation
# reload just shows the button again, and the job still completes).
#
# The whole control renders inside a turbo_frame_tag(ByokKeyChannel::
# PENDING_FRAME_ID) so both the pending render and the broadcast target the same
# frame id.
#
# The plaintext key is never sent as a named form field — the Stimulus
# controller clears the paste input before submit, and only the hidden
# envelope fields (populated by WebCrypto) are ever named/submitted.
class Ui::ByokKeyFormComponent < ApplicationComponent
  extend T::Sig

  # The keypair-generation-pending state, passed (not a flag) so its presence IS
  # "pending": #create hands one in to swap the button for a spinner subscribed
  # to `stream` — the owner's keypair stream, same untyped-streamable contract
  # as Shared::AsyncPendingComponent#stream — and its absence renders the normal
  # CRUD states. Built by the caller (controller), never on a cold page load.
  class Pending < T::Struct
    const :stream, T.untyped
  end

  # All three actions (create/seal/delete) target the same singleton
  # `profile_byok_key_path` — they differ only by HTTP verb, which
  # button_to/form_with supply — so this takes one endpoint_url, not three.
  sig do
    params(
      key_present: T::Boolean,
      public_key_pem: T.nilable(String),
      endpoint_url: String,
      pending: T.nilable(Pending)
    ).void
  end
  def initialize(key_present:, public_key_pem:, endpoint_url:, pending: nil)
    @key_present = key_present
    @public_key_pem = public_key_pem
    @endpoint_url = endpoint_url
    @pending = pending
  end

  # The Turbo Frame id this control renders inside — the same id
  # KeypairReadyBroadcast targets, so the worker's broadcast replaces this frame
  # in place.
  sig { returns(String) }
  def frame_id
    ByokKeyChannel::PENDING_FRAME_ID
  end

  # The card wrapper's classes — the pending and settled branches share it from
  # here so the string is spelled once. Ui::CardComponent's shell is px-3.5
  # only; this control wants the taller py-3 padding, so it carries its own.
  sig { returns(String) }
  def card_classes
    "bg-card border border-card-border rounded-card px-3.5 py-3"
  end

  # The heading's classes — shared by both branches from here so the string is
  # spelled once (the pending and settled cards carry the same title).
  sig { returns(String) }
  def heading_classes
    "text-sm text-ink font-bold mb-1"
  end

  sig { returns(T::Boolean) }
  def pending?
    !@pending.nil?
  end

  # The streamable the pending spinner subscribes to: the owner's keypair
  # stream, matched by ByokKeyChannel's authorization.
  sig { returns(T.untyped) }
  def keypair_stream
    T.must(@pending).stream
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
