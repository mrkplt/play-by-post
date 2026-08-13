# typed: strict

# Layout configuration for Ui::MarkdownEditorComponent. `scroll` selects which
# regions cap their height and scroll internally; the heights are keys into
# HEIGHTS, applied as max-height so overflowing content scrolls instead of
# resizing the surrounding layout.
class Ui::MarkdownEditorComponent::Config
  extend T::Sig

  # The editor's height scale, in viewport units so an editor grows with the
  # screen rather than staying fixed at a phone-sized box. Callers pick a step
  # by name; there are no ad-hoc heights, which is what keeps the editors
  # across the app visually consistent.
  HEIGHTS = T.let({
    sm: "20vh",
    md: "30vh",
    lg: "40vh",
    xl: "60vh"
  }.freeze, T::Hash[Symbol, String])

  sig { params(scroll: Symbol, edit_height: Symbol, preview_height: Symbol, toolbar: T::Boolean, preview: T::Boolean, rows: Integer).void }
  def initialize(scroll: :both, edit_height: :lg, preview_height: :md, toolbar: true, preview: true, rows: 5)
    @scroll = scroll
    @edit_height = edit_height
    @preview_height = preview_height
    @toolbar = toolbar
    @preview = preview
    @rows = rows
  end

  sig { returns(Symbol) }
  attr_reader :scroll

  sig { returns(Symbol) }
  attr_reader :edit_height

  sig { returns(Symbol) }
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
