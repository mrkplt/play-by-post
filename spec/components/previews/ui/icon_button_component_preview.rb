# @label Icon Button
class Ui::IconButtonComponentPreview < ViewComponent::Preview
  # @display bg_color "#2b2d31"
  def hamburger = render(Ui::IconButtonComponent.new(label: "Open navigation")) { "☰".html_safe }

  # @display bg_color "#2b2d31"
  def gear = render(Ui::IconButtonComponent.new(align: :center, label: "Player management")) { "⚙".html_safe }
end
