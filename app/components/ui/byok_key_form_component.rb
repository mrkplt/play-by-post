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
# The plaintext key is never sent as a named form field — the Stimulus
# controller clears the paste input before submit, and only the hidden
# envelope fields (populated by WebCrypto) are ever named/submitted.
class Ui::ByokKeyFormComponent < ApplicationComponent
  extend T::Sig

  # All three actions (create/seal/delete) target the same singleton
  # `profile_byok_key_path` — they differ only by HTTP verb, which
  # button_to/form_with supply — so this takes one endpoint_url, not three.
  sig do
    params(
      key_present: T::Boolean,
      public_key_pem: T.nilable(String),
      endpoint_url: String
    ).void
  end
  def initialize(key_present:, public_key_pem:, endpoint_url:)
    @key_present = key_present
    @public_key_pem = public_key_pem
    @endpoint_url = endpoint_url
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
