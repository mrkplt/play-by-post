# typed: strict

# Manages the current user's BYOK (bring-your-own OpenRouter key)
# EncryptedValue from the Profile screen — see Crypto::CryptoService's class
# comment for the full envelope format, and KeypairGenerationJob for why key
# generation happens on the worker, not inline here.
#
# The whole lifecycle happens in place — no action redirects. `create`
# enqueues KeypairGenerationJob (idempotent — a no-op if a keypair already
# exists for this user+value_type) and responds with a Turbo Stream swapping
# the control to its pending state; the pending spinner's frame-poll reloads
# the control (`show`) until the keypair exists and the paste form renders.
# `update` accepts the browser-sealed envelope (the Stimulus byok-key-seal
# controller's output) and `destroy` tears the whole EncryptedValue and its
# keypair down to the neutral state — a stored key cannot be retrieved or
# re-pasted, so the only way to change it is delete then set up a fresh
# keypair. Both respond with Turbo Streams that swap the control to its next
# state and refresh the profile's "Fund AI for your games" section, whose
# visibility hangs on key presence. None of these actions ever sees, and this
# controller never handles, the plaintext BYOK key — only the sealed JSON
# envelope.
class Profiles::ByokKeysController < ApplicationController
  extend T::Sig
  include ProfileScoped

  # The EncryptedValue#value_type this controller manages — the BYOK
  # OpenRouter key is the current sole consumer of the custody primitive.
  VALUE_TYPE = Crypto::StoredKeySource::OPENROUTER_KEY_VALUE_TYPE

  after_action :verify_authorized

  # The poll target: renders the control's current state into its Turbo Frame.
  # Only ever fetched by the pending spinner's frame-poll, so "no keypair yet"
  # means the job is still running — render pending again and the poll
  # continues; once the keypair exists this renders the paste form and the
  # poll stops with it.
  sig { void }
  def show
    authorize profile, :manage?

    render streams.component(pending: !keypair_exists?), layout: false
  end

  # "Set up encryption": enqueue the async keypair job and swap the button for
  # the pending spinner in place. When a keypair already exists (the idempotent
  # no-op case, or a stray double-submit) there is nothing to wait on: the same
  # stream renders the settled control instead.
  sig { void }
  def create
    authorize profile, :manage?

    KeypairGenerationJob.perform_later(owner_type: "User", owner_id: current_user.id, value_type: VALUE_TYPE)

    render_creation
  end

  sig { void }
  def update
    authorize profile, :manage?

    apply_seal
    render turbo_stream: streams.settled
  end

  sig { void }
  def destroy
    authorize profile, :manage?

    tear_down!(T.must(byok_value)) if byok_value
    flash.now[:notice] = "OpenRouter key deleted."
    render turbo_stream: streams.settled
  end

  private

  # Whether the keypair is settled decides both the toast copy and whether the
  # control renders pending — computed once so the two cannot disagree.
  sig { void }
  def render_creation
    exists = keypair_exists?
    flash.now[:notice] = exists ? "Your encryption key is ready." : "Preparing your encryption key…"
    render turbo_stream: streams.creation(pending: !exists)
  end

  # Seal the envelope if nothing blocks it, setting the outcome flash either
  # way — the caller renders the same in-place streams for every outcome.
  sig { void }
  def apply_seal
    kind, message = seal_outcome
    flash.now[kind] = message
  end

  sig { returns([ Symbol, String ]) }
  def seal_outcome
    blocker = seal_blocker
    return [ :alert, blocker ] if blocker

    seal_value!(T.must(byok_value)) ? [ :notice, "OpenRouter key saved." ] : [ :alert, "Could not save that key." ]
  end

  # The current user's BYOK EncryptedValue, or nil in the neutral state.
  # Looked up per call rather than memoized in an ivar — this controller's
  # actions touch it at most twice, and a model-holding controller ivar is a
  # view-layering leak (bin/check-view-layering R1).
  sig { returns(T.nilable(EncryptedValue)) }
  def byok_value
    EncryptedValue.find_by(owner: current_user, value_type: VALUE_TYPE)
  end

  # Whether the async keypair already exists — a presence check, not a record
  # fetch, so #show/#create can decide between pending and settled without
  # loading the model (which would drag the whole EncryptedValue into the
  # action's conditional and re-couple it to #byok_value).
  sig { returns(T::Boolean) }
  def keypair_exists?
    EncryptedValue.exists?(owner: current_user, value_type: VALUE_TYPE)
  end

  # The alert if the current key must not be sealed, or nil if sealing may
  # proceed: there must be a keypair to seal against, and no key already saved
  # (changing a saved key is delete-then-set-up, never a server-side
  # overwrite — see the class comment).
  sig { returns(T.nilable(String)) }
  def seal_blocker
    return "No keypair to seal a key against yet." unless byok_value
    return "A key is already saved. Delete it before setting a new one." if T.must(byok_value).sealed_value.present?

    nil
  end

  # Full teardown to the neutral state. The worker-database PrivateKey must be
  # destroyed explicitly first — no `dependent:` cascade spans the
  # `connects_to` boundary (see PrivateKey). Destroying the PublicKey then
  # cascades to its EncryptedValue via PublicKey's `has_one … dependent:
  # :destroy`, so no keypair or sealed value survives.
  sig { params(encrypted_value: EncryptedValue).void }
  def tear_down!(encrypted_value)
    public_key = T.must(encrypted_value.public_key)
    PrivateKey.where(public_key_id: public_key.id).destroy_all
    public_key.destroy!
  end

  # The in-place swap assembly, delegated so this controller stays thin — see
  # ByokKeyStreams. flash.now rides into the toast: nothing here redirects, so
  # a persisted flash would leak onto the next full page load.
  sig { returns(ByokKeyStreams) }
  def streams
    ByokKeyStreams.new(
      user: current_user,
      context: ByokKeyStreams::Context.new(turbo_stream: turbo_stream, helpers: helpers, flash: flash),
      endpoint_url: profile_byok_key_path
    )
  end

  # Stores the browser-sealed envelope as-is (the JSON
  # EncryptedValue#sealed_blob parses back into a Blob). Built via
  # #envelope_blob only to validate shape/presence before persisting — this
  # controller never decrypts it, so a malformed or tampered envelope is only
  # ever caught later, by CryptoService#decrypt in the worker.
  sig { params(encrypted_value: EncryptedValue).returns(T::Boolean) }
  def seal_value!(encrypted_value)
    encrypted_value.update!(sealed_value: envelope_blob.to_json)
    true
  rescue ActionController::ParameterMissing, KeyError
    false
  end

  sig { returns(Crypto::Blob) }
  def envelope_blob
    Crypto::Blob.from_params(params.require(:byok_key).permit(:wrapped_key, :iv, :ciphertext))
  end
end
