# @label Markdown Render
class Ui::MarkdownRenderComponentPreview < ViewComponent::Preview
  def default
    render(Ui::MarkdownRenderComponent.new(text: "# Heading\n\nSome **bold** text and a [link](https://example.com)."))
  end

  def scrollable
    render(Ui::MarkdownRenderComponent.new(
      text: "Paragraph line one\nline two\n\n" * 12,
      config: Ui::MarkdownRenderComponent::Config.new(scroll: true, height: 200)))
  end
end
