# @label Markdown Preview
class Ui::MarkdownPreviewComponentPreview < ViewComponent::Preview
  def default
    render(Ui::MarkdownPreviewComponent.new)
  end

  def capped
    render(Ui::MarkdownPreviewComponent.new(height: :md))
  end

  def with_extra_classes
    render(Ui::MarkdownPreviewComponent.new(
      height: :md,
      extra_class: "post-content border border-card-border rounded-card px-3 py-3"))
  end
end
