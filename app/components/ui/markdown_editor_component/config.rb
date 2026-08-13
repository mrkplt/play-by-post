# typed: strict

# Layout configuration for Ui::MarkdownEditorComponent: how tall the textarea
# is and which regions surround it.
#
# Regions are objects, not flags — a config carries the toolbar and preview it
# wants, and omitting one is how you turn it off. That keeps each region's own
# settings (the preview's height, its extra classes) with the region instead of
# spread across the editor's parameter list.
class Ui::MarkdownEditorComponent::Config
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
  sig do
    params(
      edit_height: T.nilable(Symbol),
      regions: T::Array[Ui::MarkdownEditorComponent::Region]
    ).void
  end
  def initialize(edit_height: :lg, regions: Ui::MarkdownEditorComponent::Config.default_regions)
    @edit_height = edit_height
    @regions = regions
  end

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
    @regions.select { |region| region.placement == placement }.map(&:component)
  end

  sig { returns(T::Boolean) }
  def edit_scroll?
    !@edit_height.nil?
  end

  # The textarea's max-height declaration, nil when the textarea is uncapped.
  # Config owns the scale, so it resolves the step here rather than handing a
  # bare key out; HEIGHTS.fetch raises on a step outside the scale.
  sig { returns(T.nilable(String)) }
  def edit_max_height
    height = @edit_height
    return nil if height.nil?

    "max-height: #{HEIGHTS.fetch(height)}"
  end
end
