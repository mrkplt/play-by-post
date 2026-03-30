# @label Button
class Ui::ButtonComponentPreview < ViewComponent::Preview
  def primary    = render(Ui::ButtonComponent.new(variant: :primary))   { "Primary" }
  def secondary  = render(Ui::ButtonComponent.new(variant: :secondary)) { "Secondary" }
  def danger     = render(Ui::ButtonComponent.new(variant: :danger))    { "Danger" }
  def ghost      = render(Ui::ButtonComponent.new(variant: :ghost))     { "Ghost" }
  def small      = render(Ui::ButtonComponent.new(size: :sm))           { "Small" }
  def large      = render(Ui::ButtonComponent.new(size: :lg))           { "Large" }
  def disabled   = render(Ui::ButtonComponent.new(disabled: true))      { "Disabled" }
end
