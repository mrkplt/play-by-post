# typed: strict

# A per-owner image library: the current image shown large, a grid of the
# owner's other images each with a delete control, and (when the viewer may
# manage the library) an upload button that opens the cropper modal. Drives
# both the character portrait section and the profile avatar section, so it
# takes presentation-ready data — never a raw model.
#
# Selection is click-to-preview: clicking a thumbnail (the image-select
# Stimulus controller wrapping the section) swaps the large image immediately,
# client-side, with no server round-trip. A single Save button persists the
# pending selection to `set_current_url` and the server answers with the usual
# in-place Turbo Stream + toast. There is no per-thumbnail "Use" control.
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
  # ternary is out of the output tag, per the no-logic-in-templates rule. Grouped
  # in one hash (not three top-level constants) to stay under the class's
  # constant ceiling. The image-select Stimulus controller applies the same two
  # BORDER_CLASSES client-side when the user clicks a different thumbnail, so a
  # cold load and a pending client-side selection never disagree on what
  # "selected" looks like.
  BORDER_CLASSES = T.let(
    {
      base: "w-16 h-16 rounded-control object-cover border",
      current: "border-accent ring-2 ring-accent",
      idle: "border-card-border"
    }.freeze,
    T::Hash[Symbol, String]
  )

  SAVE_BUTTON_CLASS =
    "bg-accent text-accent-ink border-0 rounded-control px-4 py-2 text-[13px] " \
    "font-extrabold cursor-pointer disabled:opacity-50 disabled:cursor-not-allowed"

  # The populated card adds column layout to the shared shell.
  sig { returns(String) }
  def populated_card_class
    "#{CARD_CLASS} flex flex-col gap-4"
  end

  sig { params(image: Item).returns(String) }
  def image_thumb_class(image)
    ring = image[:current] ? BORDER_CLASSES[:current] : BORDER_CLASSES[:idle]
    "#{BORDER_CLASSES[:base]} #{ring}"
  end

  # The image-select Stimulus wiring for one thumbnail: always a target (so the
  # controller can re-derive "which thumbnail is this image" from the DOM), but
  # only a manageable library wires the click action and the data it needs — a
  # viewer who cannot manage the library cannot select at all. Split by
  # can_manage rather than branching inside one method, so each half reads the
  # image fields it actually uses.
  sig { params(image: Item).returns(T::Hash[Symbol, T.untyped]) }
  def thumb_data(image)
    base = unmanaged_thumb_data(image)
    return base unless can_manage

    base.merge(selectable_thumb_data(image))
  end

  private

  sig { params(image: Item).returns(T::Hash[Symbol, T.untyped]) }
  def unmanaged_thumb_data(image)
    { image_select_target: "thumb", image_select_id_param: image[:id] }
  end

  sig { params(image: Item).returns(T::Hash[Symbol, T.untyped]) }
  def selectable_thumb_data(image)
    {
      action: "click->image-select#select",
      image_select_display_url_param: image[:display_url],
      image_select_set_current_url_param: image[:set_current_url],
      image_select_current_param: image[:current]
    }
  end
end
