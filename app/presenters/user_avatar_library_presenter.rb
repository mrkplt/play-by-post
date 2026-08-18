# typed: strict

# The user-avatar flavour of ImageLibraryPresenter: the user's own image
# library, always manageable (the profile is the acting user's own), with the
# profile-nested image routes.
class UserAvatarLibraryPresenter < ImageLibraryPresenter
  extend T::Sig

  sig { params(user: User, helpers: T.untyped).void }
  def initialize(user:, helpers:)
    @user = user
    super(helpers: helpers)
  end

  # The avatar library is always the acting user's own, so it is always
  # manageable — the controller only ever builds this for current_user.
  sig { override.returns(T::Boolean) }
  def can_manage?
    true
  end

  sig { override.returns(String) }
  def upload_url
    @helpers.profile_images_path
  end

  private

  sig { override.returns(T.untyped) }
  def images
    @user.user_images.with_attached_file.order(created_at: :desc)
  end

  sig { override.params(image: T.untyped).returns(String) }
  def set_current_url(image)
    @helpers.profile_image_path(image)
  end

  sig { override.params(image: T.untyped).returns(String) }
  def delete_url(image)
    @helpers.profile_image_path(image)
  end
end
