# typed: true

# CRU over the token's game's notebook entries, addressed by slug. Notebook
# entries are GM-only in every direction (NotebookEntryPolicy delegates every
# predicate to an active-GM gate), so every action here is denied to any
# non-GM member and to a banned GM. Promotion is out of this API's scope.
#
# A kanban status may be set on create and update. It never rides through a raw
# `update` of the strong params: when a request carries `status`, the value is
# validated through NotebookLaneMove — the same chokepoint the web lane move
# uses — and its permitted status attribute is merged onto the title/body params
# before the save. That single path means a future lane-transition side effect
# cannot be skipped by a machine client, and an out-of-range status is rejected
# (400 from the schema middleware for a documented enum; ActionController::
# BadRequest → uniform 400 here if the service is reached directly) rather than
# 500. Omitting status keeps the default `new` on create and leaves it unchanged
# on update.
module Api
  class NotebookEntriesController < Api::BaseController
    extend T::Sig

    sig { void }
    def index
      entries = current_game.notebook_entries
      authorize entries.new, :index?
      filtered = Api::IndexFilters.new(entries, params).apply
      @notebook_entries = T.let(filtered.to_a, T.nilable(T::Array[NotebookEntry]))
    end

    sig { void }
    def show
      @notebook_entry = T.let(find_notebook_entry, T.nilable(NotebookEntry))
      authorize @notebook_entry
    end

    sig { void }
    def create
      @notebook_entry = T.let(current_game.notebook_entries.new(write_params), T.nilable(NotebookEntry))
      entry = T.must(@notebook_entry)
      authorize entry

      if entry.save
        render :create, status: :created
      else
        render_errors(entry)
      end
    end

    sig { void }
    def update
      @notebook_entry = T.let(find_notebook_entry, T.nilable(NotebookEntry))
      entry = T.must(@notebook_entry)
      authorize entry

      if entry.update(write_params)
        render :update
      else
        render_errors(entry)
      end
    end

    private

    sig { returns(NotebookEntry) }
    def find_notebook_entry
      current_game.notebook_entries.find_by!(slug: params[:slug])
    end

    # The attributes a create/update writes: the permitted prose fields, plus —
    # only when the request carries a status — the status validated through
    # NotebookLaneMove, the shared lane-move chokepoint. Never a raw status from
    # the strong params, so status can only change through that validation path.
    sig { returns(ActionController::Parameters) }
    def write_params
      prose = notebook_entry_params
      return prose unless status_requested?

      prose.merge(NotebookLaneMove.new(params).attributes)
    end

    sig { returns(T::Boolean) }
    def status_requested?
      params.require(:notebook_entry).key?(:status)
    end

    sig { returns(ActionController::Parameters) }
    def notebook_entry_params
      params.require(:notebook_entry).permit(:title, :body)
    end
  end
end
