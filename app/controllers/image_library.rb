# typed: strict
# frozen_string_literal: true

# The CRUD an image library controller shares: list the owner's images, upload a
# new one (which becomes current), mark an existing one current, and delete one.
# CharacterImagesController and UserImagesController differ only in who the owner
# is and where the library renders, so the actions live here once and each
# controller supplies the four owner-specific hooks below.
#
# A plain module included directly (not an ActiveSupport::Concern, and not under
# app/**/concerns/ — this project's convention is explicit that we do not use
# Rails "concerns"). `requires_ancestor ApplicationController` lets Sorbet
# resolve the controller methods (params, redirect_to, current_user, authorize)
# without a per-method T.bind.
module ImageLibrary
  extend T::Sig
  extend T::Helpers
  include Kernel

  abstract!

  requires_ancestor { ApplicationController }

  sig { void }
  def create
    authorize image_collection.new
    uploaded = uploaded_image_param
    return redirect_to library_redirect_path, alert: "Please select an image to upload." unless uploaded

    save_uploaded_image(uploaded)
  end

  # Authorization runs against an unsaved instance before the lookup, so a
  # forbidden caller cannot tell a missing image from a forbidden one.
  sig { void }
  def update
    authorize image_collection.new
    image_collection.find(params[:id]).make_current!
    redirect_to library_redirect_path, notice: "Portrait updated."
  end

  sig { void }
  def destroy
    authorize image_collection.new
    image_collection.find(params[:id]).destroy
    redirect_to library_redirect_path, notice: "Image deleted."
  end

  private

  # The owner's has_many image relation (e.g. character.character_images).
  sig { abstract.returns(T.untyped) }
  def image_collection; end

  # The AttachmentUploader kind for this owner ("character_image" / "user_image").
  sig { abstract.returns(String) }
  def image_kind; end

  # The game an upload is scoped to for R2 metadata, or nil for user images.
  sig { abstract.returns(T.nilable(Game)) }
  def image_game; end

  # Where every action returns to — the library screen for this owner.
  sig { abstract.returns(String) }
  def library_redirect_path; end

  sig { params(uploaded: T.untyped).void }
  def save_uploaded_image(uploaded)
    image = build_uploaded_image(uploaded)

    if image.save
      image.make_current!
      redirect_to library_redirect_path, notice: "Portrait added."
    else
      redirect_to library_redirect_path, alert: image_error_message(image)
    end
  end

  sig { params(uploaded: T.untyped).returns(T.untyped) }
  def build_uploaded_image(uploaded)
    image = image_collection.new
    AttachmentUploader.attach(
      attachment: image.file,
      attachable: uploaded,
      context: AttachmentUploader::Context.build(
        kind: image_kind,
        owner: AttachmentUploader::Owner.build(user: current_user, game: image_game),
        naming: AttachmentUploader::Naming.build(original_filename: uploaded.original_filename)
      )
    )
    image
  end

  sig { returns(T.nilable(ActionDispatch::Http::UploadedFile)) }
  def uploaded_image_param
    image = params.dig(:image, :file)
    image if image.is_a?(ActionDispatch::Http::UploadedFile)
  end

  sig { params(image: T.untyped).returns(String) }
  def image_error_message(image)
    image.errors[:file].first || "Could not add image."
  end
end
