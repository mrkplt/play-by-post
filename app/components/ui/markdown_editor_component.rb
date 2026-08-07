# typed: strict

# A self-contained markdown editing surface: a formatting toolbar, a monospace
# textarea and a live preview, all wired to the markdown-preview and
# markdown-toolbar Stimulus controllers. Which regions cap their height and
# scroll internally is configurable so the same editor fits both inline forms
# and constrained modals.
class Ui::MarkdownEditorComponent < ApplicationComponent
  extend T::Sig

  # Layout configuration. `scroll` selects which regions cap their height and
  # scroll internally; the heights are px values applied as max-height so
  # overflowing content scrolls instead of resizing the surrounding layout.
  class Config
    extend T::Sig

    sig { params(scroll: Symbol, edit_height: Integer, preview_height: Integer, toolbar: T::Boolean, preview: T::Boolean, rows: Integer).void }
    def initialize(scroll: :both, edit_height: 320, preview_height: 256, toolbar: true, preview: true, rows: 5)
      @scroll = scroll
      @edit_height = edit_height
      @preview_height = preview_height
      @toolbar = toolbar
      @preview = preview
      @rows = rows
    end

    sig { returns(Symbol) }
    attr_reader :scroll

    sig { returns(Integer) }
    attr_reader :edit_height

    sig { returns(Integer) }
    attr_reader :preview_height

    sig { returns(T::Boolean) }
    attr_reader :toolbar

    sig { returns(T::Boolean) }
    attr_reader :preview

    sig { returns(Integer) }
    attr_reader :rows

    sig { returns(T::Boolean) }
    def edit_scroll?
      @scroll == :both || @scroll == :edit
    end

    sig { returns(T::Boolean) }
    def preview_scroll?
      @scroll == :both || @scroll == :preview
    end
  end

  DEFAULT_TEXTAREA_DATA = T.let({
    markdown_preview_target: "input",
    markdown_toolbar_target: "input",
    action: "input->markdown-preview#update"
  }.freeze, T::Hash[Symbol, T.untyped])

  sig { params(form: ActionView::Helpers::FormBuilder, field: Symbol, config: Config, value: T.nilable(String), placeholder: T.nilable(String), required: T::Boolean, data: T::Hash[Symbol, T.untyped], edit_class: String, preview_class: String, wrapper_class: String).void }
  def initialize(form:, field:, config: Config.new, value: nil, placeholder: nil, required: false, data: {}, edit_class: "", preview_class: "", wrapper_class: "")
    @form = form
    @field = field
    @config = config
    @value = value
    @placeholder = placeholder
    @required = required
    @data = data
    @edit_class = edit_class
    @preview_class = preview_class
    @wrapper_class = wrapper_class
  end

  sig { returns(String) }
  def wrapper_class
    @wrapper_class
  end

  sig { returns(String) }
  def edit_classes
    classes = [ "markdown-editor", "w-full" ]
    classes << "overflow-y-auto" if @config.edit_scroll?
    classes << @edit_class unless @edit_class.empty?
    classes.join(" ")
  end

  sig { returns(String) }
  def preview_classes
    classes = [ "markdown-base", "min-h-12", "bg-canvas", "empty:hidden" ]
    classes << "overflow-y-auto" if @config.preview_scroll?
    classes << @preview_class unless @preview_class.empty?
    classes.join(" ")
  end

  sig { returns(T.nilable(String)) }
  def edit_max_height
    "max-height: #{@config.edit_height}px" if @config.edit_scroll?
  end

  sig { returns(T.nilable(String)) }
  def preview_max_height
    "max-height: #{@config.preview_height}px" if @config.preview_scroll?
  end

  sig { returns(T::Hash[Symbol, T.untyped]) }
  def textarea_data
    DEFAULT_TEXTAREA_DATA.merge(@data)
  end

  sig { returns(T::Hash[Symbol, T.untyped]) }
  def textarea_options
    options = {
      rows: @config.rows,
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
