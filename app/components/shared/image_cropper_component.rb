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

  sig { params(upload_url: String, title: String, add_label: String).void }
  def initialize(upload_url:, title:, add_label:)
    @upload_url = T.let(upload_url, String)
    @title = T.let(title, String)
    @add_label = T.let(add_label, String)
  end

  sig { returns(String) }
  attr_reader :upload_url

  sig { returns(String) }
  attr_reader :title

  sig { returns(String) }
  attr_reader :add_label

  # Shared class string for the zoom/rotate control buttons, declared once so the
  # four buttons don't each spell it out (bin/quality-metrics dedup ceiling).
  CONTROL_BUTTON_CLASS = "px-3 py-1.5 text-sm border border-card-border rounded-control bg-card cursor-pointer"

  Control = T.type_alias { { action: String, label: String, symbol: String } }

  # The cropper's zoom/rotate controls, as data the template iterates — each maps
  # to the image-cropper Stimulus action it fires.
  sig { returns(T::Array[Control]) }
  def crop_controls
    [
      { action: "image-cropper#zoomIn", label: "Zoom in", symbol: "+" },
      { action: "image-cropper#zoomOut", label: "Zoom out", symbol: "−" },
      { action: "image-cropper#rotateLeft", label: "Rotate left", symbol: "↺" },
      { action: "image-cropper#rotateRight", label: "Rotate right", symbol: "↻" }
    ]
  end
end
