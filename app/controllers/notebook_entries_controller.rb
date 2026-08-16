# typed: strict

# The Campaign Notebook: a GM-only kanban of short entries (new / expand /
# done / discard) that can be "promoted" into a full game Page — every action
# here is GM-only, authorized solely by NotebookEntryPolicy. Neither #game nor
# #notebook_entry is backed by a before_action ivar: templates hold only
# @game_presenter/@entry_presenter, and under `# typed: strict` an ivar
# holding either raw model would itself be a violation, so each lookup is a
# private method called fresh where needed. Actions that mutate the entry
# (#update, #move) keep the mutated instance in a local rather than
# re-resolving it, so validation errors survive into the re-render.
class NotebookEntriesController < ApplicationController
  extend T::Sig

  after_action :verify_authorized

  helper_method :game_presenter, :game_routes

  sig { void }
  def index
    authorize game.notebook_entries.new, :index?
    @notebook_board = T.let(game_presenter.notebook_board, T.nilable(NotebookBoardPresenter))
  end

  sig { void }
  def new
    new_entry = game.notebook_entries.new(body: ContentTemplate.body_for(game: game, content_type: "note"))
    authorize new_entry
    assign_entry_presenter(new_entry)
  end

  sig { void }
  def create
    new_entry = game.notebook_entries.new(notebook_entry_params)
    authorize new_entry
    return redirect_to game_notebook_entries_path(game), notice: "Entry created." if new_entry.save

    render_create_failed(new_entry)
  end

  sig { void }
  def edit
    assign_entry_presenter(authorized_entry)
  end

  # Saving keeps the writer on the edit screen — an entry is long-form markdown
  # and being re-rendered from scratch on every save loses their place.
  sig { void }
  def update
    entry = authorized_entry
    outcome = SaveOutcome.for(entry.update(notebook_entry_params), "entry")
    assign_entry_presenter(entry)
    InPlaceSave.new(self, outcome: outcome, forward_to: edit_game_notebook_entry_path(game, entry)).respond
  end

  sig { void }
  def destroy
    authorized_entry.destroy
    redirect_to game_notebook_entries_path(game), notice: "Entry deleted."
  end

  private

  # A nil capability is Pundit's default: the predicate named for the action.
  sig { params(capability: T.nilable(Symbol)).returns(NotebookEntry) }
  def authorized_entry(capability = nil)
    notebook_entry.tap { |entry| authorize entry, capability }
  end

  sig { params(notebook_entry: NotebookEntry).void }
  def assign_entry_presenter(notebook_entry)
    @entry_presenter = T.let(NotebookEntryPresenter.new(notebook_entry), T.nilable(NotebookEntryPresenter))
  end

  sig { params(new_entry: NotebookEntry).void }
  def render_create_failed(new_entry)
    assign_entry_presenter(new_entry)
    respond_to_create_failure
  end

  sig { void }
  def respond_to_create_failure
    respond_to do |format|
      format.turbo_stream { render :create_failed }
      format.html { render :new, status: :unprocessable_content }
    end
  end

  sig { returns(Game) }
  def game
    Game.find_by!(slug: params[:game_id])
  end

  sig { returns(NotebookEntry) }
  def notebook_entry
    game.notebook_entries.find_by!(slug: params[:slug])
  end

  # Memoized rather than set by a before_action: the actions that render it
  # (create/update on validation failure) are not named after it.
  sig { returns(GamePresenter) }
  def game_presenter
    @game_presenter ||= T.let(GamePresenter.new(game, policy: policy(game), urls: self), T.nilable(GamePresenter))
  end

  sig { returns(GameRoutesPresenter) }
  def game_routes = GameRoutesPresenter.new(game_presenter, urls: self)

  sig { returns(ActionController::Parameters) }
  def notebook_entry_params
    params.require(:notebook_entry).permit(:title, :body)
  end
end
