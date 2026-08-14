# typed: strict

# Cloudflare Turnstile widget for a form: the `cf-turnstile` container plus the
# loader script. Renders nothing when Turnstile is disabled. Enforcement is
# server-side (TurnstileVerifier via TurnstileVerification), not here.
#
# The container carries the `turnstile` Stimulus controller, which discards the
# widget's spent single-use token and waits for its replacement. Forms that
# navigate on submit never need it — they get a fresh widget with the next page
# load; forms submitted via fetch do, or every submit after the first replays a
# spent token. Such a form drives the controller from its own (see
# feedback_controller.js).
class Ui::TurnstileWidgetComponent < ApplicationComponent
  extend T::Sig

  THEMES = T.let(%i[auto light dark].freeze, T::Array[Symbol])

  STIMULUS_CONTROLLER = T.let("turnstile", String)

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

  # The Stimulus controller sits on a wrapper rather than on the widget itself.
  # Turnstile replaces the widget element's contents (reset swaps in a fresh
  # iframe), so the controller needs an element it owns and Turnstile will not
  # rewrite. It also keeps `data-action` unambiguous — Turnstile reads that
  # attribute on the widget as the challenge's label, which is not Stimulus's
  # meaning for it.
  sig { returns(ActiveSupport::SafeBuffer) }
  def widget_tag
    content_tag(:div, content_tag(:div, "", class: "cf-turnstile", data: widget_data), data: wrapper_data)
  end

  sig { returns(T::Hash[Symbol, String]) }
  def wrapper_data
    { controller: STIMULUS_CONTROLLER }
  end

  # `action:` here is Turnstile's own label for the form being protected.
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
