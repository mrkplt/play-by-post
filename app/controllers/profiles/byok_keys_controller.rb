# typed: strict

# Manages the current user's BYOK (bring-your-own OpenRouter key)
# EncryptedValue from the Profile screen — see Crypto::CryptoService's class
# comment for the full envelope format, and KeypairGenerationJob for why key
# generation happens on the worker, not inline here.
#
# `create` generates the EncryptedValue's dedicated keypair (idempotent — a
# no-op if one already exists for this user+value_type) so the browser has a
# public key to encrypt to. `update` accepts the browser-sealed envelope (the
# Stimulus byok-key-seal controller's output) and stores it against a keypair
# that has no key sealed yet. `destroy` tears the whole EncryptedValue and its
# keypair down to the neutral state — a stored key cannot be retrieved or
# re-pasted, so the only way to change it is delete then set up a fresh
# keypair. None of these actions ever sees, and this controller never handles,
# the plaintext BYOK key — only the sealed JSON envelope.
class Profiles::ByokKeysController < ApplicationController
  extend T::Sig
  include ProfileScoped

  # The EncryptedValue#value_type this controller manages — the BYOK
  # OpenRouter key is the current sole consumer of the custody primitive.
  VALUE_TYPE = Crypto::StoredKeySource::OPENROUTER_KEY_VALUE_TYPE

  after_action :verify_authorized

  sig { void }
  def create
    authorize profile, :manage?

    KeypairGenerationJob.perform_later(owner_type: "User", owner_id: current_user.id, value_type: VALUE_TYPE)
    redirect_to profile_path, notice: keypair_pending_notice
  end

  sig { void }
  def update
    authorize profile, :manage?

    blocker = seal_blocker
    return redirect_to profile_path, alert: blocker if blocker

    seal_value!(T.must(byok_value)) ? seal_succeeded : seal_failed
  end

  sig { void }
  def destroy
    authorize profile, :manage?

    tear_down!(T.must(byok_value)) if byok_value
    redirect_to profile_path, notice: "OpenRouter key deleted."
  end

  private

  # The current user's BYOK EncryptedValue, or nil in the neutral state.
  # Looked up per call rather than memoized in an ivar — this controller's
  # actions touch it at most twice, and a model-holding controller ivar is a
  # view-layering leak (bin/check-view-layering R1).
  sig { returns(T.nilable(EncryptedValue)) }
  def byok_value
    EncryptedValue.find_by(owner: current_user, value_type: VALUE_TYPE)
  end

  # The alert to redirect with if the current key must not be sealed, or nil if
  # sealing may proceed: there must be a keypair to seal against, and no key
  # already saved (changing a saved key is delete-then-set-up, never a
  # server-side overwrite — see the class comment).
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

  sig { returns(String) }
  def keypair_pending_notice
    EncryptedValue.exists?(owner: current_user, value_type: VALUE_TYPE) ? "Your encryption key is ready." : "Preparing your encryption key…"
  end

  sig { void }
  def seal_succeeded
    redirect_to profile_path, notice: "OpenRouter key saved."
  end

  sig { void }
  def seal_failed
    redirect_to profile_path, alert: "Could not save that key."
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
