# typed: strict

# A self-contained markdown editing surface: a monospace textarea wired to the
# markdown-preview and markdown-toolbar Stimulus controllers, with regions laid
# out around it.
#
# The editor does not know what a toolbar or a preview is. Its config carries a
# collection of regions (see Region), each of which reports where it sits; the
# editor renders those above and below the textarea. Adding a third region
# later needs no change here.
class Ui::MarkdownEditorComponent < ApplicationComponent
  extend T::Sig

  # Layout configuration lives in Ui::MarkdownEditorComponent::Config
  # (app/components/ui/markdown_editor_component/config.rb).

  DEFAULT_TEXTAREA_DATA = T.let({
    markdown_preview_target: "input",
    markdown_toolbar_target: "input",
    action: "input->markdown-preview#update"
  }.freeze, T::Hash[Symbol, T.untyped])

  sig { params(form: ActionView::Helpers::FormBuilder, field: Symbol, config: Config, rows: Integer, value: T.nilable(String), placeholder: T.nilable(String), required: T::Boolean, data: T::Hash[Symbol, T.untyped], edit_class: String, wrapper_class: String).void }
  def initialize(form:, field:, config: Config.new, rows: 5, value: nil, placeholder: nil, required: false, data: {}, edit_class: "", wrapper_class: "")
    @form = form
    @field = field
    @config = config
    @rows = rows
    @value = value
    @placeholder = placeholder
    @required = required
    @data = data
    @edit_class = edit_class
    @wrapper_class = wrapper_class
  end

  sig { returns(String) }
  def wrapper_class
    @wrapper_class
  end

  sig { returns(T::Array[ViewComponent::Base]) }
  def regions_above
    @config.components_placed(:above)
  end

  sig { returns(T::Array[ViewComponent::Base]) }
  def regions_below
    @config.components_placed(:below)
  end

  sig { returns(String) }
  def edit_classes
    classes = [ "markdown-editor", "w-full" ]
    classes << "overflow-y-auto" if @config.edit_scroll?
    classes << @edit_class unless @edit_class.empty?
    classes.join(" ")
  end

  sig { returns(T.nilable(String)) }
  def edit_max_height
    @config.edit_max_height
  end

  sig { returns(T::Hash[Symbol, T.untyped]) }
  def textarea_data
    DEFAULT_TEXTAREA_DATA.merge(@data)
  end

  sig { returns(T::Hash[Symbol, T.untyped]) }
  def textarea_options
    options = {
      rows: @rows,
      placeholder: @placeholder,
      required: @required,
      data: textarea_data,
      class: edit_classes,
      style: edit_max_height
    }
    options[:value] = @value unless @value.nil?
    options
  end
end
