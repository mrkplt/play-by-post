# typed: true
# frozen_string_literal: true

# Pushes the finished BYOK keypair to the owner waiting on the Profile screen.
#
# After "Set up encryption" enqueues KeypairGenerationJob, the owner's Profile
# screen shows a pending spinner frame subscribed to `[owner, :byok_keypair]`.
# Once KeypairGenerationJob has created the EncryptedValue and its keypair, it
# calls this to replace that frame — on the owner's stream only — with the
# paste-a-key form (now that a public key exists to encrypt to), and to drop a
# "ready" toast into #toast_layer. Only the owner subscribes to their stream
# (ByokKeyChannel), so no other user ever receives it.
class KeypairReadyBroadcast
  extend T::Sig

  READY_TOAST = { message: "Your encryption key is ready.", variant: :success }.freeze

  sig { params(encrypted_value: EncryptedValue).void }
  def initialize(encrypted_value)
    @encrypted_value = encrypted_value
  end

  sig { void }
  def call
    stream = [ owner, :byok_keypair ]

    Turbo::StreamsChannel.broadcast_replace_to(
      *stream,
      target: ByokKeyChannel::PENDING_FRAME_ID,
      renderable: form_component,
      layout: false
    )
    Turbo::StreamsChannel.broadcast_replace_to(
      *stream,
      target: "toast_layer",
      renderable: Ui::ToastComponent.new(toasts: [ READY_TOAST ]),
      layout: false
    )
  end

  private

  # The paste-a-key form: keypair ready, no key sealed yet, so the owner can now
  # encrypt their OpenRouter key to the freshly generated public half.
  sig { returns(Ui::ByokKeyFormComponent) }
  def form_component
    Ui::ByokKeyFormComponent.new(
      key_present: false,
      public_key_pem: T.must(@encrypted_value.public_key).public_key,
      endpoint_url: Rails.application.routes.url_helpers.profile_byok_key_path
    )
  end

  sig { returns(User) }
  def owner
    T.cast(@encrypted_value.owner, User)
  end
end
