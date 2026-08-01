# @label Toggle Switch
class Ui::ToggleSwitchComponentPreview < ViewComponent::Preview
  def off = render(Ui::ToggleSwitchComponent.new(on: false))
  def on  = render(Ui::ToggleSwitchComponent.new(on: true))
end
