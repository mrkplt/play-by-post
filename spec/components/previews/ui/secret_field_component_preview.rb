# @label Secret Field
class Ui::SecretFieldComponentPreview < ViewComponent::Preview
  # @label Default
  def default
    render(Ui::SecretFieldComponent.new(
             value: "https://play-by-post.example.com/rss/feed?token=deadbeef",
             label: "RSS Feed URL"
           ))
  end
end
