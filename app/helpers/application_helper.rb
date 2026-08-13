# typed: true

module ApplicationHelper
  extend T::Sig

  def icon(name, library: Icons.config.default_library, **html_options)
    icon = Icons::Icon.new(name: name, library: library, arguments: html_options)
    svg = icon.svg

    # Replace or add class attribute if provided
    if html_options[:class].present?
      svg = svg.sub(/class="[^"]*"/, "class=\"#{html_options[:class]}\"")
    end

    # icon.svg is trusted markup from the `icons` gem (no user input), so it is
    # marked html-safe. Built as a SafeBuffer rather than `svg.html_safe` so the
    # safety is explicit at the source and needs no inline cop disable.
    ActiveSupport::SafeBuffer.new(svg)
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
