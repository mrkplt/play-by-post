# typed: strict

# The live preview pane beneath a markdown textarea: an empty target the
# `markdown-preview` Stimulus controller fills as the author types. Purely
# presentational — it holds no content of its own, and pairs with any textarea
# carrying the controller's input target.
#
# The pane owns its own appearance — every preview in the app is the same
# surface. `content_class` is a scoping hook for domain-specific markdown
# styling (`post-content`, `character-sheet-content`), not a way to restyle the
# box; height is a step on Ui::MarkdownEditorComponent::Config::HEIGHTS.
class Ui::MarkdownPreviewComponent < ApplicationComponent
  extend T::Sig

  BASE = T.let(
    "markdown-base min-h-12 bg-canvas " \
    "border border-card-border rounded-card px-3 py-3 mt-4",
    String
  )

  sig { params(height: T.nilable(Symbol), content_class: String).void }
  def initialize(height: nil, content_class: "")
    @height = height
    @content_class = content_class
  end

  sig { returns(T::Boolean) }
  def capped?
    !@height.nil?
  end

  sig { returns(String) }
  def classes
    classes = [ BASE ]
    classes << "overflow-y-auto" if capped?
    classes << @content_class unless @content_class.empty?
    classes.join(" ")
  end

  sig { returns(T.nilable(String)) }
  def max_height
    height = @height
    return nil if height.nil?

    "max-height: #{Ui::MarkdownEditorComponent::Config::HEIGHTS.fetch(height)}"
  end
end
