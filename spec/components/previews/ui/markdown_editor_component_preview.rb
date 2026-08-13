# @label Markdown Editor
class Ui::MarkdownEditorComponentPreview < ViewComponent::Preview
  def default
    render(Ui::MarkdownEditorComponent.new(form: form_builder, field: :content))
  end

  def capped_textarea_and_preview
    render(Ui::MarkdownEditorComponent.new(
      form: form_builder, field: :content,
      config: Ui::MarkdownEditorComponent::Config.new(edit_height: :md)))
  end

  def capped_textarea_only
    render(Ui::MarkdownEditorComponent.new(
      form: form_builder, field: :content,
      config: Ui::MarkdownEditorComponent::Config.new(
        edit_height: :md,
        regions: [
          Ui::MarkdownEditorComponent::ToolbarRegion.new,
          Ui::MarkdownEditorComponent::PreviewRegion.new
        ])))
  end

  def capped_preview_only
    render(Ui::MarkdownEditorComponent.new(
      form: form_builder, field: :content,
      config: Ui::MarkdownEditorComponent::Config.new(edit_height: nil)))
  end

  def without_toolbar
    render(Ui::MarkdownEditorComponent.new(
      form: form_builder, field: :content,
      config: Ui::MarkdownEditorComponent::Config.new(
        regions: [ Ui::MarkdownEditorComponent::PreviewRegion.new(height: :md) ])))
  end

  def without_preview
    render(Ui::MarkdownEditorComponent.new(
      form: form_builder, field: :content,
      config: Ui::MarkdownEditorComponent::Config.new(
        regions: [ Ui::MarkdownEditorComponent::ToolbarRegion.new ])))
  end

  def textarea_only
    render(Ui::MarkdownEditorComponent.new(
      form: form_builder, field: :content,
      config: Ui::MarkdownEditorComponent::Config.new(regions: [])))
  end

  private

  def form_builder
    form = nil
    helpers.form_with(model: Post.new, url: "#") { |f| form = f }
    form
  end
end
