# @label Section Label
class Ui::SectionLabelComponentPreview < ViewComponent::Preview
  def default = render(Ui::SectionLabelComponent.new) { "Active Scenes" }
end
