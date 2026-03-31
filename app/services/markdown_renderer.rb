# typed: true

class MarkdownRenderer
  extend T::Sig

  include ActionView::Helpers::SanitizeHelper

  ALLOWED_TAGS = T.let(
    %w[p br strong em del a ul ol li h1 h2 h3 h4 h5 h6 blockquote pre code hr table thead tbody tr th td].freeze,
    T::Array[String]
  )
  ALLOWED_ATTRIBUTES = T.let(%w[href].freeze, T::Array[String])

  sig { params(text: T.nilable(String)).returns(String) }
  def self.render(text)
    new.render(text)
  end

  sig { params(text: T.nilable(String)).returns(String) }
  def render(text)
    return "" if text.blank?

    T.must(sanitize(
      markdown_parser.render(text),
      tags: ALLOWED_TAGS,
      attributes: ALLOWED_ATTRIBUTES
    ))
  end

  private

  sig { returns(Redcarpet::Markdown) }
  def markdown_parser
    renderer = Redcarpet::Render::HTML.new(
      hard_wrap: true,
      no_images: true,
      no_links: false,
      filter_html: true
    )
    Redcarpet::Markdown.new(
      renderer,
      autolink: true,
      tables: true,
      strikethrough: true,
      fenced_code_blocks: true,
      no_intra_emphasis: true
    )
  end
end
