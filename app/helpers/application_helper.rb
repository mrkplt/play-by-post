# typed: true

module ApplicationHelper
  extend T::Sig

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

    # Use sanitize with SVG allowlist to satisfy Rails/OutputSafety cop
    sanitize(svg, tags: %w[svg g path circle rect line polyline polygon text tspan use defs clipPath mask pattern linearGradient radialGradient stop animate set], attributes: %w[viewBox xmlns d fill stroke stroke-width stroke-linecap stroke-linejoin stroke-miterlimit stroke-dasharray stroke-dashoffset stroke-opacity fill-opacity opacity transform style class id x y width height r rx ry cx cy x1 y1 x2 y2 points d fill-rule clip-rule mask-type gradientUnits spreadMethod x1 y1 x2 y2 fx fy fr r offset stop-color stop-opacity])
  end

  def render_markdown(text)
    MarkdownRenderer.render(text)
  end

  # Passive "last export" text shown beside the (always-enabled) export button.
  sig { params(receipt: GameExportRequest).returns(String) }
  def last_export_notice(receipt)
    "Last export: #{T.unsafe(self).time_ago_in_words(T.must(receipt.succeeded_at))} ago"
  end

  # "Export All Games" helper text on the profile page: the last-export notice
  # when a receipt exists, otherwise generic delivery-window/expiry copy.
  sig { params(receipt: T.nilable(GameExportRequest)).returns(String) }
  def export_all_games_notice(receipt)
    return last_export_notice(receipt) if receipt

    "You'll receive an email with a download link within a few minutes; the link expires after 7 days."
  end
end
