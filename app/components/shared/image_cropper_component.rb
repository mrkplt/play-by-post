# typed: strict

# The upload-and-crop modal: a hidden dialog holding a file picker, the
# Cropper.js surface, zoom/rotate controls, and a form that posts the
# square-cropped result to `upload_url`. All behaviour is the image-cropper
# Stimulus controller; this component only lays out the modal it drives.
#
# Rendered once per library section (character portraits, profile avatar); the
# library component's "Add image" button opens it.
class Shared::ImageCropperComponent < ApplicationComponent
  extend T::Sig

  sig { params(upload_url: String, title: String).void }
  def initialize(upload_url:, title:)
    @upload_url = T.let(upload_url, String)
    @title = T.let(title, String)
  end

  sig { returns(String) }
  attr_reader :upload_url

  sig { returns(String) }
  attr_reader :title
end
