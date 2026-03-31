# @label Badge
class Ui::BadgeComponentPreview < ViewComponent::Preview
  def yellow = render(Ui::BadgeComponent.new(variant: :yellow)) { "Private" }
  def gray   = render(Ui::BadgeComponent.new(variant: :gray))   { "Resolved" }
  def green  = render(Ui::BadgeComponent.new(variant: :green))  { "Active" }
  def blue   = render(Ui::BadgeComponent.new(variant: :blue))   { "GM" }
end
