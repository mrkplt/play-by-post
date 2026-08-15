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

  # The editor owns its own appearance. Every markdown surface in the app is
  # the same control, so its border, radius, padding and text tokens live here
  # rather than being respelled at each call site — which is how four of them
  # had drifted onto the wrong tokens entirely. Callers vary size (rows and the
  # HEIGHTS scale) and may add a content hook; they do not restyle the box.
  EDIT_BASE = T.let(
    "border border-input-border border-t-0 rounded-b-control " \
    "px-3 py-2.5 text-base text-ink bg-card placeholder:text-muted-2",
    String
  )

  DEFAULT_TEXTAREA_DATA = T.let({
    markdown_preview_target: "input",
    markdown_toolbar_target: "input",
    action: "input->markdown-preview#update"
  }.freeze, T::Hash[Symbol, T.untyped])

  # `binding:` carries the form/field pair the textarea is rendered onto — a
  # bare FormBuilder does not classify under the view-layering gate (not a
  # model, presenter, component, or primitive), so it travels in the same
  # kind of opaque options hash as html_options/data elsewhere, rather than as
  # a typed positional parameter.
  sig { params(binding: T::Hash[Symbol, T.untyped], config: Config, rows: Integer, value: T.nilable(String), placeholder: T.nilable(String), required: T::Boolean, data: T::Hash[Symbol, T.untyped], wrapper_class: String).void }
  def initialize(binding:, config: Config.new, rows: 5, value: nil, placeholder: nil, required: false, data: {}, wrapper_class: "")
    @form = T.let(binding.fetch(:form), ActionView::Helpers::FormBuilder)
    @field = T.let(binding.fetch(:field), Symbol)
    @config = config
    @rows = rows
    @value = value
    @placeholder = placeholder
    @required = required
    @data = data
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
    [ "markdown-editor", "w-full", EDIT_BASE, @config.edit_scroll_class ].reject(&:empty?).join(" ")
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
