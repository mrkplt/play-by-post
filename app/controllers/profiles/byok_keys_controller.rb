# typed: strict

# Manages the current user's BYOK (bring-your-own OpenRouter key)
# EncryptedValue from the Profile screen — see Crypto::CryptoService's class
# comment for the full envelope format, and KeypairGenerationJob for why key
# generation happens on the worker, not inline here.
#
# `create` generates the EncryptedValue's dedicated keypair (idempotent — a
# no-op if one already exists for this user+value_type) so the browser has a
# public key to encrypt to. `update` accepts the browser-sealed envelope (the
# Stimulus byok-key-seal controller's output) and stores it — this is both
# "add a key" and "replace an existing key": there is no separate replace
# action, since sealing simply overwrites `sealed_value`. Neither action ever
# sees, and this controller never handles, the plaintext BYOK key — only the
# sealed JSON envelope.
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

    encrypted_value = EncryptedValue.find_by(owner: current_user, value_type: VALUE_TYPE)
    return redirect_to profile_path, alert: "No keypair to seal a key against yet." unless encrypted_value

    seal_value!(encrypted_value) ? seal_succeeded : seal_failed
  end

  private

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
