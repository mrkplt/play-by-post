# typed: strict

# Cloudflare Turnstile widget — a mostly-invisible bot challenge dropped into a
# form. Renders the `cf-turnstile` container (which the Cloudflare script hydrates
# into a hidden `cf-turnstile-response` input on the form) plus the loader script.
#
# When Turnstile is disabled (the test environment, or a build without keys) the
# component renders nothing, so forms elsewhere aren't forced to satisfy a token.
#
# Server-side verification of the produced token is TurnstileVerifier's job,
# invoked via the TurnstileVerification controller module — rendering the widget
# alone does not enforce anything.
class Ui::TurnstileWidgetComponent < ApplicationComponent
  extend T::Sig

  THEMES = T.let(%i[auto light dark].freeze, T::Array[Symbol])

  sig { params(theme: Symbol, action: T.nilable(String)).void }
  def initialize(theme: :auto, action: nil)
    raise ArgumentError, "Unknown theme: #{theme}" unless THEMES.include?(theme)

    @theme = theme
    @action = action
  end

  sig { returns(T.nilable(ActiveSupport::SafeBuffer)) }
  def call
    return unless Turnstile.enabled?

    safe_join([ widget_tag, script_tag ])
  end

  private

  sig { returns(ActiveSupport::SafeBuffer) }
  def widget_tag
    content_tag(:div, "", class: "cf-turnstile", data: widget_data)
  end

  sig { returns(T::Hash[Symbol, String]) }
  def widget_data
    data = { sitekey: Turnstile.site_key, theme: @theme.to_s }
    data[:action] = @action if @action.present?
    data
  end

  sig { returns(ActiveSupport::SafeBuffer) }
  def script_tag
    helpers.javascript_include_tag(Turnstile::SCRIPT_URL, async: true, defer: true)
  end
end
