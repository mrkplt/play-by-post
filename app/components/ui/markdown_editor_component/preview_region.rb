# typed: strict

# The live preview pane, sitting below the textarea. Owns the preview's height
# step and its content hook, so the editor never handles them — it just renders
# whatever regions the config carries.
class Ui::MarkdownEditorComponent::PreviewRegion
  extend T::Sig
  include Ui::MarkdownEditorComponent::Region

  sig { params(height: T.nilable(Symbol), content_class: String).void }
  def initialize(height: nil, content_class: "")
    @height = height
    @content_class = content_class
  end

  sig { override.returns(Symbol) }
  def placement
    :below
  end

  sig { override.returns(ViewComponent::Base) }
  def component
    Ui::MarkdownPreviewComponent.new(height: @height, content_class: @content_class)
  end
end
