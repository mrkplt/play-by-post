# typed: strict

# Read-only markdown display. Renders sanitized HTML from raw markdown text via
# MarkdownRenderer and applies the shared markdown-base typography. An optional
# height cap turns it into a self-scrolling region for constrained layouts.
class Ui::MarkdownRenderComponent < ApplicationComponent
  extend T::Sig

  # Display configuration. `scroll` caps the region height (px) and scrolls
  # internally; when false the content flows at its natural height.
  class Config
    extend T::Sig

    sig { params(scroll: T::Boolean, height: Integer).void }
    def initialize(scroll: false, height: 480)
      @scroll = scroll
      @height = height
    end

    sig { returns(T::Boolean) }
    attr_reader :scroll

    sig { returns(Integer) }
    attr_reader :height
  end

  sig { params(text: T.nilable(String), config: Config, content_class: String, content_attributes: T::Hash[Symbol, T.untyped]).void }
  def initialize(text:, config: Config.new, content_class: "", content_attributes: {})
    @text = text
    @config = config
    @content_class = content_class
    @content_attributes = content_attributes
  end

  # MarkdownRenderer.render returns an html-safe SafeBuffer (it is the
  # sanitization boundary), so the template renders this directly with no
  # output-safety call.
  sig { returns(ActiveSupport::SafeBuffer) }
  def rendered
    MarkdownRenderer.render(@text)
  end

  sig { returns(String) }
  def classes
    classes = [ "markdown-base" ]
    classes << "overflow-y-auto" if @config.scroll
    classes << @content_class unless @content_class.empty?
    classes.join(" ")
  end

  sig { returns(T.nilable(String)) }
  def max_height
    "max-height: #{@config.height}px" if @config.scroll
  end

  sig { returns(T::Hash[Symbol, T.untyped]) }
  def content_attributes
    @content_attributes
  end
end
