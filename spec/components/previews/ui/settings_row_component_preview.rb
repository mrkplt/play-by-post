# @label Settings Row
class Ui::SettingsRowComponentPreview < ViewComponent::Preview
  # @display bg_color "#ffffff"
  def default
    render(Ui::SettingsRowComponent.new(label: "Display Name", sub: "Shown to other players")) { "Edit" }
  end

  def last_row
    render(Ui::SettingsRowComponent.new(label: "Export All Games", last: true)) { "Request" }
  end
end
