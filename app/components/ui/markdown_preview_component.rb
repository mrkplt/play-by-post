# typed: strict

# The live preview pane beneath a markdown textarea: an empty target the
# `markdown-preview` Stimulus controller fills as the author types. Purely
# presentational — it holds no content of its own, and pairs with any textarea
# carrying the controller's input target.
#
# Height is a step on Ui::MarkdownEditorComponent::Config::HEIGHTS; passing one
# caps the pane and scrolls its overflow, and omitting it lets the pane grow.
class Ui::MarkdownPreviewComponent < ApplicationComponent
  extend T::Sig

  BASE = T.let("markdown-base min-h-12 bg-canvas", String)

  sig { params(height: T.nilable(Symbol), extra_class: String).void }
  def initialize(height: nil, extra_class: "")
    @height = height
    @extra_class = extra_class
  end

  sig { returns(T::Boolean) }
  def capped?
    !@height.nil?
  end

  sig { returns(String) }
  def classes
    classes = [ BASE ]
    classes << "overflow-y-auto" if capped?
    classes << @extra_class unless @extra_class.empty?
    classes.join(" ")
  end

  sig { returns(T.nilable(String)) }
  def max_height
    height = @height
    return nil if height.nil?

    "max-height: #{Ui::MarkdownEditorComponent::Config::HEIGHTS.fetch(height)}"
  end
end
