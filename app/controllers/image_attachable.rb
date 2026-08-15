# typed: strict
# frozen_string_literal: true

# The "attach an uploaded image from params" step PostsController and
# ScenesController both do identically (only the params key differs — the
# AttachmentUploader `kind:` is that key with an `_image` suffix in both
# cases, e.g. :scene -> "scene_image", so it is derived rather than passed).
# A plain module included directly (not an ActiveSupport::Concern, and not
# under app/**/concerns/ — this project's convention is explicit that we do
# not use Rails "concerns").
module ImageAttachable
  extend T::Sig

  private

  sig { params(record: T.untyped, game: T.nilable(Game), param_key: Symbol).void }
  def attach_uploaded_image(record, game, param_key:)
    T.bind(self, T.all(ActionController::Base, ImageAttachable))
    image = uploaded_image(param_key)
    return unless image

    AttachmentUploader.attach(
      attachment: record.image, attachable: image,
      context: AttachmentUploader::Context.build(
        kind: "#{param_key}_image",
        user: current_user, game: game, original_filename: image.original_filename
      )
    )
  end

  sig { params(param_key: Symbol).returns(T.nilable(ActionDispatch::Http::UploadedFile)) }
  def uploaded_image(param_key)
    T.bind(self, T.all(ActionController::Base, ImageAttachable))
    image = params.dig(param_key, :image)
    image if image.is_a?(ActionDispatch::Http::UploadedFile)
  end
end
