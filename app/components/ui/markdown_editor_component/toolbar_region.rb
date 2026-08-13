# typed: strict

# The formatting toolbar, sitting above the textarea. Holds no configuration:
# Shared::MarkdownToolbarComponent is self-contained, so this only states where
# it goes.
class Ui::MarkdownEditorComponent::ToolbarRegion
  extend T::Sig
  include Ui::MarkdownEditorComponent::Region

  sig { override.returns(Symbol) }
  def placement
    :above
  end

  sig { override.returns(ViewComponent::Base) }
  def component
    Shared::MarkdownToolbarComponent.new
  end
end
