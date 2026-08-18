# typed: strict

# The current user's avatar library, nested under their profile. The CRUD lives
# in ImageLibrary; this controller supplies the user-owned hooks. A user only
# ever manages their own library, so the collection is always current_user's and
# UserImagePolicy#manage? confirms ownership.
class UserImagesController < ApplicationController
  extend T::Sig
  include ImageLibrary

  after_action :verify_authorized

  private

  sig { override.returns(T.untyped) }
  def image_collection
    current_user.user_images
  end

  sig { override.returns(String) }
  def image_kind
    "user_image"
  end

  sig { override.returns(T.nilable(Game)) }
  def image_game
    nil
  end

  sig { override.returns(String) }
  def library_redirect_path
    profile_path
  end
end
