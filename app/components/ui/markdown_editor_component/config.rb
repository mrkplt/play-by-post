# typed: strict

# Layout configuration for Ui::MarkdownEditorComponent: how tall the textarea
# is and which regions surround it.
#
# Regions are objects, not flags — a config carries the toolbar and preview it
# wants, and omitting one is how you turn it off. That keeps each region's own
# settings (the preview's height, its extra classes) with the region instead of
# spread across the editor's parameter list.
#
# A T::Struct rather than a plain class: this is data constructed by callers
# (`Config.new(...)`, `Config.with_preview(...)`), not a class with behaviour
# of its own beyond deriving values from that data — the view-layering gate's
# CONTAINER SHAPES rule reaches for T::Struct exactly here ("the same data
# when something CONSTRUCTS it").
class Ui::MarkdownEditorComponent::Config < T::Struct
  extend T::Sig

  # The editor's height scale, in viewport units so an editor grows with the
  # screen rather than staying fixed at a phone-sized box. Callers pick a step
  # by name; there are no ad-hoc heights, which is what keeps the editors
  # across the app visually consistent.
  HEIGHTS = T.let({
    sm: "20vh",
    md: "30vh",
    lg: "40vh",
    xl: "60vh"
  }.freeze, T::Hash[Symbol, String])

  sig { returns(T::Array[Ui::MarkdownEditorComponent::Region]) }
  def self.default_regions
    [
      Ui::MarkdownEditorComponent::ToolbarRegion.new,
      Ui::MarkdownEditorComponent::PreviewRegion.new(height: :md)
    ]
  end

  # The default surface: a toolbar above, a preview below capped at :md, and a
  # textarea capped at :lg. Pass `regions: []` for a bare textarea.
  const :edit_height, T.nilable(Symbol), default: :lg
  const :regions, T::Array[Ui::MarkdownEditorComponent::Region], factory: -> { Ui::MarkdownEditorComponent::Config.default_regions }

  # The overwhelmingly common surface: a toolbar above and a live preview
  # below. `content_class` is the preview's domain styling hook and is the only
  # thing most callers need to state.
  sig do
    params(
      content_class: String,
      edit_height: T.nilable(Symbol),
      preview_height: Symbol
    ).returns(Ui::MarkdownEditorComponent::Config)
  end
  def self.with_preview(content_class: "", edit_height: nil, preview_height: :md)
    new(
      edit_height: edit_height,
      regions: [
        Ui::MarkdownEditorComponent::ToolbarRegion.new,
        Ui::MarkdownEditorComponent::PreviewRegion.new(height: preview_height, content_class: content_class)
      ]
    )
  end

  sig { params(placement: Symbol).returns(T::Array[ViewComponent::Base]) }
  def components_placed(placement)
    regions.select { |region| region.placement == placement }.map(&:component)
  end

  sig { returns(T::Boolean) }
  def edit_scroll?
    !edit_height.nil?
  end

  # The scroll utility class the editor's textarea needs when it is capped to
  # a max-height, or "" when it is not — Config owns edit_height, so it
  # resolves this alongside edit_max_height rather than handing edit_scroll?
  # out for the editor to branch on itself.
  sig { returns(String) }
  def edit_scroll_class
    edit_scroll? ? "overflow-y-auto" : ""
  end

  # The textarea's max-height declaration, nil when the textarea is uncapped.
  # Config owns the scale, so it resolves the step here rather than handing a
  # bare key out; HEIGHTS.fetch raises on a step outside the scale.
  sig { returns(T.nilable(String)) }
  def edit_max_height
    height = edit_height
    return nil if height.nil?

    "max-height: #{HEIGHTS.fetch(height)}"
  end
end
