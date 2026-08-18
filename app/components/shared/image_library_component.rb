# typed: strict

# A per-owner image library: the current image shown large, a grid of the
# owner's other images each with set-current / delete controls, and (when the
# viewer may manage the library) an upload button that opens the cropper modal.
# Drives both the character portrait section and the profile avatar section, so
# it takes presentation-ready data — never a raw model.
#
# Each entry in `images` is a ready-made hash (an Item): the thumbnail URL, the
# large URL, whether it is current, and the set-current / delete action URLs.
# The presenter builds these; the component only decides markup.
class Shared::ImageLibraryComponent < ApplicationComponent
  extend T::Sig

  Item = T.type_alias do
    {
      id: Integer,
      thumb_url: String,
      display_url: String,
      current: T::Boolean,
      set_current_url: String,
      delete_url: String
    }
  end

  sig do
    params(
      title: String,
      images: T::Array[Item],
      can_manage: T::Boolean,
      empty_text: String
    ).void
  end
  def initialize(title:, images:, can_manage:, empty_text:)
    @title = T.let(title, String)
    @images = T.let(images, T::Array[Item])
    @can_manage = T.let(can_manage, T::Boolean)
    @empty_text = T.let(empty_text, String)
  end

  sig { returns(String) }
  attr_reader :title

  sig { returns(T::Array[Item]) }
  attr_reader :images

  sig { returns(T::Boolean) }
  attr_reader :can_manage

  sig { returns(String) }
  attr_reader :empty_text

  # The one image marked current — the large portrait/avatar at the top of the
  # section, or nil when the library is empty.
  sig { returns(T.nilable(Item)) }
  def current_image
    images.find { |image| image[:current] }
  end

  sig { returns(T::Boolean) }
  def any_images?
    images.any?
  end

  # The card shell both the populated and empty states share, declared once so
  # the class string isn't spelled out twice (bin/quality-metrics dedup ceiling).
  CARD_CLASS = "bg-card border border-card-border rounded-card p-4"

  # The thumbnail's CSS: a shared base, ringed when this image is the current
  # one so the grid shows which is selected. Kept here (not the template) so the
  # ternary is out of the output tag, per the no-logic-in-templates rule.
  THUMB_BASE = "w-16 h-16 rounded-control object-cover border"
  CURRENT_RING = "border-accent ring-2 ring-accent"
  IDLE_BORDER = "border-card-border"

  # The populated card adds column layout to the shared shell.
  sig { returns(String) }
  def populated_card_class
    "#{CARD_CLASS} flex flex-col gap-4"
  end

  sig { params(image: Item).returns(String) }
  def image_thumb_class(image)
    "#{THUMB_BASE} #{image[:current] ? CURRENT_RING : IDLE_BORDER}"
  end
end
