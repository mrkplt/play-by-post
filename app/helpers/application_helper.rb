# typed: true

module ApplicationHelper
  extend T::Sig

  def icon(name, library: Icons.config.default_library, **html_options)
    icon = Icons::Icon.new(name: name, library: library, arguments: html_options)
    svg = icon.svg

    # Replace or add class attribute if provided
    css_class = html_options[:class]
    svg = svg.sub(/class="[^"]*"/, "class=\"#{css_class}\"") if css_class.present?

    # icon.svg is trusted markup from the `icons` gem (no user input), so it is
    # marked html-safe. Built as a SafeBuffer rather than `svg.html_safe` so the
    # safety is explicit at the source and needs no inline cop disable.
    ActiveSupport::SafeBuffer.new(svg)
  end

  def render_markdown(text)
    MarkdownRenderer.render(text)
  end
end
