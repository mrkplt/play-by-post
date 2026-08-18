# typed: strict

# Turns an owner's uploaded-image library into the ready-made data
# Shared::ImageLibraryComponent renders: one Item hash per image (thumbnail and
# display URLs, the current flag, and the set-current / delete action URLs),
# plus the upload URL and whether the viewer may manage the library.
#
# Owner-agnostic: the two subclasses (character portraits, user avatars) supply
# only the collection, the URLs, and the manage capability. The URL builders
# take `urls` (the controller/view-context) so no route is constructed in a
# template.
class ImageLibraryPresenter
  extend T::Sig
  extend T::Helpers

  abstract!

  sig { params(helpers: T.untyped).void }
  def initialize(helpers:)
    @helpers = helpers
  end

  # The library's images as component-ready Item hashes, newest first.
  sig { returns(T::Array[Shared::ImageLibraryComponent::Item]) }
  def items
    images.map { |image| item_for(image) }
  end

  sig { abstract.returns(T::Boolean) }
  def can_manage?; end

  sig { abstract.returns(String) }
  def upload_url; end

  private

  # The owner's images, eager-loading the attachment so each URL is one query.
  sig { abstract.returns(T.untyped) }
  def images; end

  # The set-current URL for one image (a PATCH on the member).
  sig { abstract.params(_image: T.untyped).returns(String) }
  def set_current_url(_image); end

  # The delete URL for one image (a DELETE on the member).
  sig { abstract.params(_image: T.untyped).returns(String) }
  def delete_url(_image); end

  sig { params(image: T.untyped).returns(Shared::ImageLibraryComponent::Item) }
  def item_for(image)
    {
      id: image.id,
      thumb_url: @helpers.url_for(image.thumbnail_variant),
      display_url: @helpers.url_for(image.display_variant),
      current: image.current?,
      set_current_url: set_current_url(image),
      delete_url: delete_url(image)
    }
  end
end
