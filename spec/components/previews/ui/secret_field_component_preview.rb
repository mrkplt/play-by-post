# @label Secret Field
class Ui::SecretFieldComponentPreview < ViewComponent::Preview
  # @display bg_color "#ffffff"
  def default
    render(Ui::SecretFieldComponent.new(
      value: "https://example.com/feeds?token=abc123def456",
      label: "Feed URL"
    ))
  end
end
