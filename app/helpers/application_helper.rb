# typed: true

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
    MarkdownRenderer.render(text)
  end
end
