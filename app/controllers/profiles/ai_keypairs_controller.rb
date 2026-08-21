# typed: strict

# Manages the current user's BYOK (bring-your-own OpenRouter key) custody
# keypair from the Profile screen — see AiKeypairs::CryptoService's class
# comment for the full envelope format, and AiKeypairGenerationJob for why
# key generation happens on the worker, not inline here.
#
# `create` generates a keypair (idempotent — a no-op if one already exists)
# so the browser has a public key to encrypt to. `update` accepts the
# browser-sealed envelope (the Stimulus byok-key-seal controller's output)
# and stores it — this is both "add a key" and "replace an existing key":
# there is no separate replace action, since sealing simply overwrites
# `sealed_key`. Neither action ever sees, and this controller never handles,
# the plaintext BYOK key — only the sealed JSON envelope.
class Profiles::AiKeypairsController < ApplicationController
  extend T::Sig
  include ProfileScoped

  after_action :verify_authorized

  sig { void }
  def create
    authorize profile, :manage?

    AiKeypairGenerationJob.perform_later(owner_type: "User", owner_id: current_user.id)
    redirect_to profile_path, notice: keypair_pending_notice
  end

  sig { void }
  def update
    authorize profile, :manage?

    keypair = AiKeypair.find_by(owner: current_user)
    return redirect_to profile_path, alert: "No keypair to seal a key against yet." unless keypair

    seal_key!(keypair) ? seal_succeeded(keypair) : seal_failed
  end

  private

  sig { returns(String) }
  def keypair_pending_notice
    AiKeypair.exists?(owner: current_user) ? "Your encryption key is ready." : "Preparing your encryption key…"
  end

  sig { params(keypair: AiKeypair).void }
  def seal_succeeded(keypair)
    current_user.update!(ai_key_reference: keypair.fingerprint)
    redirect_to profile_path, notice: "OpenRouter key saved."
  end

  sig { void }
  def seal_failed
    redirect_to profile_path, alert: "Could not save that key."
  end

  # Stores the browser-sealed envelope as-is (the JSON AiKeypair#sealed_blob
  # parses back into a Blob). Built via #envelope_blob only to validate
  # shape/presence before persisting — this controller never decrypts it, so
  # a malformed or tampered envelope is only ever caught later, by
  # CryptoService#decrypt in the worker.
  sig { params(keypair: AiKeypair).returns(T::Boolean) }
  def seal_key!(keypair)
    keypair.update!(sealed_key: envelope_blob.to_json)
    true
  rescue ActionController::ParameterMissing, KeyError
    false
  end

  sig { returns(AiKeypairs::Blob) }
  def envelope_blob
    AiKeypairs::Blob.from_params(params.require(:ai_keypair).permit(:wrapped_key, :iv, :ciphertext))
  end
end
