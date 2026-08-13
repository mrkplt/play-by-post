# typed: strict

# The lane picker for a Campaign Notebook entry: a <select> of the kanban
# statuses that submits itself on change, moving the entry between swimlanes
# without a page navigation.
#
# It is the only control on a notebook board row — every other action lives on
# the entry's edit screen — and it also appears on that edit screen, so a GM can
# move an entry without returning to the board.
class Shared::NotebookLaneSelectComponent < ApplicationComponent
  extend T::Sig

  STATUS_LABELS = T.let({
    "new" => "New",
    "expand" => "Expand",
    "done" => "Done",
    "discard" => "Discard"
  }.freeze, T::Hash[String, String])

  SELECT_CLASS = T.let(
    "border border-input-border rounded-control px-2 py-1.5 text-xs text-ink bg-card",
    String
  )

  # Where this picker is rendered decides how the move is answered. On the
  # :board the response swaps the affected lanes in place; :standalone (the
  # entry's edit screen) has no lanes to swap, so the controller redirects back
  # to the entry instead.
  #
  # The mode travels as an explicit form field, NOT as the absence of
  # `data-turbo-stream`. Turbo accepts a stream response for *any* unsafe
  # request regardless of that attribute (`requestAcceptsTurboStreamResponse`
  # is `!request.isSafe || hasAttribute(...)`), so a PATCH always advertises
  # `text/vnd.turbo-stream.html` and `respond_to`'s format.html branch would
  # never run. Discriminating on a parameter is the only reliable signal.
  RESPONSE_MODES = T.let(%i[board standalone].freeze, T::Array[Symbol])

  sig { params(game: Game, notebook_entry: NotebookEntry, mode: Symbol).void }
  def initialize(game:, notebook_entry:, mode: :board)
    @game = game
    @notebook_entry = notebook_entry
    @mode = mode
  end

  sig { returns(Symbol) }
  attr_reader :mode

  sig { returns(Game) }
  attr_reader :game

  sig { returns(NotebookEntry) }
  attr_reader :notebook_entry

  sig { returns(T.nilable(String)) }
  def selected_status
    notebook_entry.status
  end

  sig { returns(T::Array[[ String, String ]]) }
  def status_options
    NotebookEntry::STATUSES.map { |status| [ T.must(STATUS_LABELS[status]), status ] }
  end

  sig { returns(T::Hash[Symbol, T.untyped]) }
  def form_data
    { turbo_stream: true }
  end

  # Every row on a board renders this component, so the control needs an id of
  # its own — a shared `notebook_entry_status` would make each row's label
  # point at the first row's select.
  sig { returns(String) }
  def select_id
    "notebook_entry_status_#{notebook_entry.slug}"
  end

  # "Lane" alone is identical on every row; a screen reader needs to know
  # which entry it is about to move.
  sig { returns(String) }
  def accessible_label
    "Lane for #{notebook_entry.title}"
  end
end
