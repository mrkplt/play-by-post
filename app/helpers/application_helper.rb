module ApplicationHelper
  def render_markdown(text)
    return "" if text.blank?

    renderer = Redcarpet::Render::HTML.new(
      hard_wrap: true,
      no_images: true,
      no_links: false,
      filter_html: true
    )
    markdown = Redcarpet::Markdown.new(renderer,
      autolink: true,
      tables: true,
      strikethrough: true,
      fenced_code_blocks: true
    )
    sanitize(markdown.render(text))
  end
end
