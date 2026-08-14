# typed: strict

# The Campaign Notebook: a GM-only kanban of short entries (new / expand /
# done / discard) that can be "promoted" into a full game Page — every action
# here is GM-only, authorized solely by NotebookEntryPolicy. `@notebook_entry`
# stays the raw AR record (Pundit and update/destroy need it); the presenter
# every view actually renders is `@entry_presenter`, rebuilt via
# #assign_entry_presenter after every mutation so it reflects current state.
class NotebookEntriesController < ApplicationController
  extend T::Sig

  before_action :set_game
  before_action :set_notebook_entry, only: %i[edit update destroy move promote]
  after_action :verify_authorized

  helper_method :game_presenter

  sig { void }
  def index
    authorize T.must(@game).notebook_entries.new, :index?
    @notebook_board = T.let(game_presenter.notebook_board, T.nilable(NotebookBoardPresenter))
  end

  sig { void }
  def new
    notebook_entry = T.must(@game).notebook_entries.new
    authorize notebook_entry
    assign_entry_presenter(notebook_entry)
  end

  sig { void }
  def create
    new_entry = T.must(@game).notebook_entries.new(notebook_entry_params)
    authorize new_entry
    return redirect_to game_notebook_entries_path(@game), notice: "Entry created." if new_entry.save

    assign_entry_presenter(new_entry)
    respond_to do |format|
      format.turbo_stream { render :create_failed }
      format.html { render :new, status: :unprocessable_content }
    end
  end

  sig { void }
  def edit
    authorize @notebook_entry
    assign_entry_presenter(notebook_entry)
  end

  sig { void }
  def update
    authorize @notebook_entry

    if notebook_entry.update(notebook_entry_params)
      redirect_to edit_game_notebook_entry_path(@game, @notebook_entry), notice: "Entry updated."
    else
      assign_entry_presenter(notebook_entry)
      render :edit, status: :unprocessable_content
    end
  end

  sig { void }
  def destroy
    authorize @notebook_entry
    notebook_entry.destroy
    redirect_to game_notebook_entries_path(@game), notice: "Entry deleted."
  end

  sig { void }
  def move
    authorize @notebook_entry, :manage?

    lane_move = NotebookLaneMove.new(params)
    notebook_entry.update!(lane_move.attributes)
    respond_to_move(lane_move)
  end

  sig { void }
  def promote
    authorize @notebook_entry, :manage?

    page = NotebookEntryPromotion.new(notebook_entry).call
    redirect_to game_page_path(@game, page), notice: "Promoted to a page."
  end

  private

  # Branches on an explicit form field, not request format: Turbo advertises
  # turbo-stream for every unsafe request, so format.html would be dead code.
  sig { params(lane_move: NotebookLaneMove).void }
  def respond_to_move(lane_move)
    if lane_move.standalone?
      redirect_to edit_game_notebook_entry_path(@game, @notebook_entry), notice: "Entry moved."
    else
      assign_entry_presenter(notebook_entry)
      render :move, formats: :turbo_stream
    end
  end

  sig { params(notebook_entry: NotebookEntry).void }
  def assign_entry_presenter(notebook_entry)
    @entry_presenter = T.let(NotebookEntryPresenter.new(notebook_entry), T.nilable(NotebookEntryPresenter))
  end

  sig { void }
  def set_game
    @game = T.let(Game.find(params[:game_id]), T.nilable(Game))
  end

  sig { void }
  def set_notebook_entry
    @notebook_entry = T.let(T.must(@game).notebook_entries.find_by!(slug: params[:slug]), T.nilable(NotebookEntry))
  end

  sig { returns(NotebookEntry) }
  def notebook_entry
    T.must(@notebook_entry)
  end

  # Memoized rather than set by a before_action: the actions that render it
  # (create/update on validation failure) are not named after it.
  sig { returns(GamePresenter) }
  def game_presenter
    @game_presenter ||= T.let(GamePresenter.new(T.must(@game), policy: policy(@game)), T.nilable(GamePresenter))
  end

  sig { returns(ActionController::Parameters) }
  def notebook_entry_params
    params.require(:notebook_entry).permit(:title, :body)
  end
end
