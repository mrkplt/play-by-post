# typed: strict

# The live preview pane, sitting below the textarea. Owns the preview's height
# step and any caller-supplied classes, so the editor never handles them — it
# just renders whatever regions the config carries.
class Ui::MarkdownEditorComponent::PreviewRegion
  extend T::Sig
  include Ui::MarkdownEditorComponent::Region

  sig { params(height: T.nilable(Symbol), extra_class: String).void }
  def initialize(height: nil, extra_class: "")
    @height = height
    @extra_class = extra_class
  end

  sig { override.returns(Symbol) }
  def placement
    :below
  end

  sig { override.returns(ViewComponent::Base) }
  def component
    Ui::MarkdownPreviewComponent.new(height: @height, extra_class: @extra_class)
  end
end
