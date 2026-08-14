# typed: strict
# frozen_string_literal: true

# The "attach an uploaded image from params" step PostsController and
# ScenesController both do identically (only the params key and
# AttachmentUploader `kind:` differ). A plain module included directly (not
# an ActiveSupport::Concern, and not under app/**/concerns/ — this project's
# convention is explicit that we do not use Rails "concerns").
module ImageAttachable
  extend T::Sig

  private

  sig { params(record: T.untyped, game: T.nilable(Game), param_key: Symbol, kind: String).void }
  def attach_uploaded_image(record, game, param_key:, kind:)
    T.bind(self, T.all(ActionController::Base, ImageAttachable))
    image = params.dig(param_key, :image)
    return unless image.respond_to?(:original_filename)

    AttachmentUploader.attach(
      attachment: record.image, attachable: image, kind: kind,
      user: current_user, game: game, original_filename: image.original_filename
    )
  end
end
