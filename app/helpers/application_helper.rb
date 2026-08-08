# typed: true

module ApplicationHelper
  extend T::Sig

  def icon(name, library: Icons.config.default_library, **html_options)
    icon = Icons::Icon.new(name: name, library: library, arguments: html_options)
    svg = icon.svg

    # Replace hardcoded colors with currentColor so CSS can control the color
    # NOTE: Icons gem transformations lowercase viewBox, so we must do this at runtime
    svg = svg.gsub(/stroke="#[0-9A-Fa-f]{6}"/, 'stroke="currentColor"')
    svg = svg.gsub(/fill="#[0-9A-Fa-f]{6}"/, 'fill="currentColor"')

    # Add class attribute if provided
    if html_options[:class].present?
      svg = svg.sub(/class="[^"]*"/, "class=\"#{html_options[:class]}\"")
    end

    svg.html_safe # rubocop:disable Rails/OutputSafety
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
