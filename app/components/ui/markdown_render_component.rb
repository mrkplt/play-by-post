# typed: strict

# Read-only markdown display. Renders sanitized HTML from raw markdown text via
# MarkdownRenderer and applies the shared markdown-base typography. An optional
# height cap turns it into a self-scrolling region for constrained layouts.
class Ui::MarkdownRenderComponent < ApplicationComponent
  extend T::Sig

  # Display configuration. `mode: :scroll` caps the region height (px) and
  # scrolls internally; `:flow` (the default) lets content flow at its
  # natural height.
  class Config
    extend T::Sig

    MODES = T.let(%i[flow scroll].freeze, T::Array[Symbol])

    sig { params(mode: Symbol, height: Integer).void }
    def initialize(mode: :flow, height: 480)
      raise ArgumentError, "Unknown mode: #{mode}" unless MODES.include?(mode)

      @mode = mode
      @height = height
    end

    sig { returns(T::Boolean) }
    def scroll
      @mode == :scroll
    end

    sig { returns(Integer) }
    attr_reader :height
  end

  # Named content-styling variants. Each maps to the typography/colour classes
  # for a display context so callers pass a named `variant:` rather than a raw
  # utility string — the component owns the CSS. `:plain` (default) adds nothing
  # beyond the shared markdown-base.
  #
  # `content_class` remains only for a NAMED co-located content class the caller
  # supplies (e.g. "post-content", "character-sheet-content") — a semantic style
  # hook, not raw utilities. Passing utilities through it is what
  # bin/check-component-css-args forbids.
  VARIANTS = T.let({
    plain:          "",
    post_body:      "post-content text-body-ink leading-[1.65] text-base",
    post_body_ooc:  "post-content text-body-ink leading-[1.65] text-sm",
    description:    "text-[13px] text-muted-2 border-t border-card-divider py-3",
    summary_amber:  "prose prose-sm max-w-none text-summary-amber-body",
    summary_slate:  "prose prose-sm max-w-none text-summary-slate-body",
    draft:          "post-content text-sm text-body-ink mb-3 border border-tint-blue-border rounded-control p-3 bg-card"
  }.freeze, T::Hash[Symbol, String])

  sig do
    params(
      text: T.nilable(String),
      config: Config,
      variant: Symbol,
      content_class: String,
      content_attributes: T::Hash[Symbol, T.untyped]
    ).void
  end
  def initialize(text:, config: Config.new, variant: :plain, content_class: "", content_attributes: {})
    raise ArgumentError, "Unknown variant: #{variant}" unless VARIANTS.key?(variant)

    @text = text
    @config = config
    # Resolve the variant's classes and any caller-supplied named content class
    # into one string up front, so #classes stays a simple join and the instance
    # carries the derived value rather than both inputs.
    @content_class = T.let([ VARIANTS.fetch(variant), content_class ].reject(&:empty?).join(" "), String)
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
    scroll_class = @config.scroll ? "overflow-y-auto" : ""
    [ "markdown-base", scroll_class, @content_class ].reject(&:empty?).join(" ")
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
