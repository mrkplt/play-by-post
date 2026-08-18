# typed: true

# A per-owner image library entry: one uploaded, already-cropped image that an
# owner (a Character or a User) keeps in its library and may mark as its current
# portrait/avatar. The two adopters — CharacterImage and UserImage — differ only
# in which record they belong to, so everything shared lives here and each adopter
# supplies just its owner.
#
# Deliberately a plain module the model `include`s, not an
# ActiveSupport::Concern (bin/check-concerns), mirroring Versionable::Model.
# The adopter declares the two things Rails macros can't be shared through a
# plain include — `has_one_attached :file` and `validate :acceptable_image` —
# right at the class, so the wiring stays visible; everything behavioural lives
# here. The includer is an ActiveRecord model, so `transaction`, `update_all`,
# and `file` resolve without a per-method bind.
#
# Images are cropped to a square in the browser before upload (see
# image_cropper_controller.js), so the stored blob is already square; the
# variants below only downscale to fixed sizes for each render surface, the same
# way scene banners and post images defined their own sizes.
module UploadedImage
  module Model
    extend T::Sig
    extend T::Helpers

    abstract!

    requires_ancestor { ActiveRecord::Base }

    # Accepted upload content types and the byte ceiling — the same set the old
    # Post/Scene attachments enforced.
    IMAGE_TYPES = T.let(%w[image/jpeg image/png image/gif image/webp].freeze, T::Array[String])
    IMAGE_MAX_SIZE = T.let(10.megabytes, Integer)

    # Render sizes. `display` is the full portrait/avatar shown on a profile or
    # character screen; `thumbnail` is the small square used in the library grid
    # and inline roster surfaces. Both fill a square because the upload is
    # already square-cropped.
    DISPLAY_SIZE = T.let(512, Integer)
    THUMBNAIL_SIZE = T.let(96, Integer)

    # The owner this image belongs to (a Character or a User). Declared by the
    # adopter so the module stays agnostic about the association name.
    sig { abstract.returns(T.untyped) }
    def owner; end

    # The owner's other library entries — every sibling that shares this image's
    # owner, this one excluded. `make_current!` clears their flag so at most one
    # is current. Declared by the adopter because the foreign key differs.
    sig { abstract.returns(T.untyped) }
    def siblings; end

    # The large square variant for a portrait/avatar display surface. `file` is
    # the Active Storage attachment the adopter installs with `has_one_attached`;
    # each model's tapioca RBI declares it, so it is read through T.unsafe(self)
    # here the same way Draftable::Model reads its per-model column.
    sig { returns(T.untyped) }
    def display_variant
      T.unsafe(self).file.variant(resize_to_fill: [ DISPLAY_SIZE, DISPLAY_SIZE ], format: :jpeg, quality: 85)
    end

    # The small square variant for the library grid / inline roster.
    sig { returns(T.untyped) }
    def thumbnail_variant
      T.unsafe(self).file.variant(resize_to_fill: [ THUMBNAIL_SIZE, THUMBNAIL_SIZE ], format: :jpeg, quality: 85)
    end

    # Make this the owner's current image: clear the flag on every sibling and
    # set it here, in one transaction so the owner is never left with two current
    # images. update_all skips callbacks/validation on the bulk clear — the flag
    # is the only thing changing.
    sig { void }
    def make_current!
      transaction do
        siblings.update_all(current: false)
        update!(current: true)
      end
    end

    # Shared validation the adopter wires with `validate :acceptable_image`.
    sig { void }
    def acceptable_image
      file = T.unsafe(self).file
      return unless file.attached?

      blob = file.blob
      errors.add(:file, "must be less than 10MB") unless blob.byte_size <= IMAGE_MAX_SIZE

      unless IMAGE_TYPES.include?(blob.content_type)
        errors.add(:file, "must be a JPEG, PNG, GIF, or WebP image")
      end
    end
  end
end
