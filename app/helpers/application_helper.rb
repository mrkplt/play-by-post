module ApplicationHelper
  def icon(name, library: Icons.config.default_library, **html_options)
    icon = Icons::Icon.new(name: name, library: library, arguments: html_options)
    svg = icon.svg

    # Replace hardcoded colors with currentColor so CSS can control the color
    svg = svg.gsub(/stroke="#[0-9A-Fa-f]{6}"/, 'stroke="currentColor"')
    svg = svg.gsub(/fill="#[0-9A-Fa-f]{6}"/, 'fill="currentColor"')

    # Add class attribute if provided
    if html_options[:class].present?
      svg = svg.sub(/<svg/, "<svg class=\"#{html_options[:class]}\"")
    end

    svg.html_safe
  end

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
      fenced_code_blocks: true,
      no_intra_emphasis: true
    )
    sanitize(markdown.render(text),
      tags: %w[p br strong em del a ul ol li h1 h2 h3 h4 h5 h6 blockquote pre code hr table thead tbody tr th td],
      attributes: %w[href])
  end
end
