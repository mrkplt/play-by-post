# @label Markdown Editor
class Ui::MarkdownEditorComponentPreview < ViewComponent::Preview
  def default
    render(Ui::MarkdownEditorComponent.new(form: form_builder, field: :content))
  end

  def scroll_edit_and_preview
    render(Ui::MarkdownEditorComponent.new(
      form: form_builder, field: :content,
      config: Ui::MarkdownEditorComponent::Config.new(scroll: :both, edit_height: 256, preview_height: 256)))
  end

  def scroll_edit_only
    render(Ui::MarkdownEditorComponent.new(
      form: form_builder, field: :content,
      config: Ui::MarkdownEditorComponent::Config.new(scroll: :edit, edit_height: 256)))
  end

  def scroll_preview_only
    render(Ui::MarkdownEditorComponent.new(
      form: form_builder, field: :content,
      config: Ui::MarkdownEditorComponent::Config.new(scroll: :preview, preview_height: 256)))
  end

  def without_toolbar
    render(Ui::MarkdownEditorComponent.new(
      form: form_builder, field: :content,
      config: Ui::MarkdownEditorComponent::Config.new(toolbar: false)))
  end

  def without_preview
    render(Ui::MarkdownEditorComponent.new(
      form: form_builder, field: :content,
      config: Ui::MarkdownEditorComponent::Config.new(preview: false)))
  end

  private

  def form_builder
    form = nil
    helpers.form_with(model: Post.new, url: "#") { |f| form = f }
    form
  end
end
