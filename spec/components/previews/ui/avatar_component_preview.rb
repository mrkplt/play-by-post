# @label Avatar
class Ui::AvatarComponentPreview < ViewComponent::Preview
  def gold  = render(Ui::AvatarComponent.new(name: "Vex Marrowgate"))
  def dark  = render(Ui::AvatarComponent.new(name: "GM", tone: :dark))
  def muted = render(Ui::AvatarComponent.new(name: "Kess", tone: :muted))
  def blue  = render(Ui::AvatarComponent.new(name: "Sera", tone: :blue))
  def large = render(Ui::AvatarComponent.new(name: "Vex", size: :lg))
end
