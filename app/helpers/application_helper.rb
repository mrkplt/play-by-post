# typed: true

module ApplicationHelper
  extend T::Sig

  def icon(name, library: Icons.config.default_library, **html_options)
    icon = Icons::Icon.new(name: name, library: library, arguments: html_options)
    svg = icon.svg

    # Add class attribute if provided
    if html_options[:class].present?
      svg = svg.sub(/<svg/, "<svg class=\"#{html_options[:class]}\"")
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
