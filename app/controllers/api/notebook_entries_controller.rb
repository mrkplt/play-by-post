# typed: true

# CRU over the token's game's notebook entries, addressed by slug. Notebook
# entries are GM-only in every direction (NotebookEntryPolicy delegates every
# predicate to an active-GM gate), so every action here is denied to any
# non-GM member and to a banned GM. Status/lane moves and promotion are out of
# this API's scope: strong params permit only title and body.
module Api
  class NotebookEntriesController < Api::BaseController
    extend T::Sig

    sig { void }
    def index
      entries = current_game.notebook_entries
      authorize entries.new, :index?
      @notebook_entries = T.let(entries.to_a, T.nilable(T::Array[NotebookEntry]))
    end

    sig { void }
    def show
      @notebook_entry = T.let(find_notebook_entry, T.nilable(NotebookEntry))
      authorize @notebook_entry
    end

    sig { void }
    def create
      @notebook_entry = T.let(current_game.notebook_entries.new(notebook_entry_params), T.nilable(NotebookEntry))
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

      if entry.update(notebook_entry_params)
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

    sig { returns(ActionController::Parameters) }
    def notebook_entry_params
      params.require(:notebook_entry).permit(:title, :body)
    end
  end
end
