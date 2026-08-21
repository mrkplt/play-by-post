# typed: strict

# The BYOK (bring-your-own OpenRouter key) settings control — add or replace
# an owner's OpenRouter API key without the plaintext ever reaching the
# server. Three states, driven entirely by whether a keypair/sealed key
# exists yet (no raw model reaches this component — a presenter/controller
# passes plain values):
#
#   1. No keypair yet: a "Set up encryption" button that POSTs to
#      `generate_url` (Profiles::AiKeypairsController#create), which enqueues
#      AiKeypairGenerationJob and redirects back here once it exists.
#   2. Keypair exists, `public_key_pem` present: the paste-a-key form, wired
#      to the `byok-key-seal` Stimulus controller, which encrypts the pasted
#      key client-side (WebCrypto) to `public_key_pem` and submits only the
#      sealed envelope to `seal_url`.
#   3. `key_present` true: same form (sealing again simply replaces the
#      stored envelope — there is no separate "replace" endpoint), with
#      copy indicating a key is already configured.
#
# The plaintext key is never sent as a named form field — the Stimulus
# controller clears the paste input before submit, and only the hidden
# envelope fields (populated by WebCrypto) are ever named/submitted.
class Ui::ByokKeyFormComponent < ApplicationComponent
  extend T::Sig

  sig do
    params(
      key_present: T::Boolean,
      public_key_pem: T.nilable(String),
      generate_url: String,
      seal_url: String
    ).void
  end
  def initialize(key_present:, public_key_pem:, generate_url:, seal_url:)
    @key_present = key_present
    @public_key_pem = public_key_pem
    @generate_url = generate_url
    @seal_url = seal_url
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
  attr_reader :generate_url

  sig { returns(String) }
  attr_reader :seal_url

  # Copy that differs between the "add a key" and "replace a key" states,
  # keyed by #key_present? — a single lookup rather than three separate
  # ternaries on the same predicate.
  COPY = T.let(
    {
      true => {
        heading: "OpenRouter key",
        submit_label: "Replace key",
        status_text: "A key is configured. Pasting a new one replaces it."
      },
      false => {
        heading: "Bring your own OpenRouter key",
        submit_label: "Save key",
        status_text: "No key configured yet."
      }
    }.freeze,
    T::Hash[T::Boolean, T::Hash[Symbol, String]]
  )

  sig { returns(String) }
  def heading
    COPY.fetch(key_present?).fetch(:heading)
  end

  sig { returns(String) }
  def submit_label
    COPY.fetch(key_present?).fetch(:submit_label)
  end

  sig { returns(String) }
  def status_text
    COPY.fetch(key_present?).fetch(:status_text)
  end
end
