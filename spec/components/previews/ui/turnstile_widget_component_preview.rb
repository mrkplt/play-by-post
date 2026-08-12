# @label Turnstile Widget
class Ui::TurnstileWidgetComponentPreview < ViewComponent::Preview
  # Renders with the always-pass Cloudflare test site key in dev.
  def auto = render(Ui::TurnstileWidgetComponent.new)
  def light = render(Ui::TurnstileWidgetComponent.new(theme: :light))
  def dark = render(Ui::TurnstileWidgetComponent.new(theme: :dark))
  def with_action = render(Ui::TurnstileWidgetComponent.new(action: "sign_in"))
end
