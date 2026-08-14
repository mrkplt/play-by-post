# typed: strict

# The Campaign Notebook: a GM-only kanban of short entries (new / expand /
# done / discard) that can be "promoted" into a full game Page. Unlike
# PagesController, every action here is GM-only — there is no read path for
# other members.
#
# Access control is NotebookEntryPolicy's alone: every action authorizes, so
# there is no `require_gm!` guard restating the same rule here. Actions that
# are not CRUD name the capability they need (`manage?`) rather than borrowing
# `update?`, which asks whether the row may be modified — a different question
# that merely has the same answer while GM and owner are the same person.
class NotebookEntriesController < ApplicationController
  extend T::Sig

  before_action :set_game
  before_action :set_notebook_entry, only: %i[edit update destroy move promote]
  after_action :verify_authorized

  helper_method :game_presenter

  sig { void }
  def index
    authorize T.must(@game).notebook_entries.new, :index?
    @notebook_board = T.let(
      NotebookBoardPresenter.new(entries_for(T.must(@game))), T.nilable(NotebookBoardPresenter)
    )
  end

  sig { void }
  def new
    notebook_entry = T.must(@game).notebook_entries.new
    authorize notebook_entry
    @notebook_entry_presenter = T.let(
      NotebookEntryPresenter.new(notebook_entry), T.nilable(NotebookEntryPresenter)
    )
  end

  sig { void }
  def create
    notebook_entry = T.must(@game).notebook_entries.new(notebook_entry_params)
    authorize notebook_entry

    if notebook_entry.save
      redirect_to game_notebook_entries_path(@game), notice: "Entry created."
    else
      @notebook_entry_presenter = T.let(
        NotebookEntryPresenter.new(notebook_entry), T.nilable(NotebookEntryPresenter)
      )
      respond_to do |format|
        format.turbo_stream { render :create_failed }
        format.html { render :new, status: :unprocessable_content }
      end
    end
  end

  sig { void }
  def edit
    authorize @notebook_entry
    @notebook_entry_presenter = T.let(
      NotebookEntryPresenter.new(T.must(@notebook_entry)), T.nilable(NotebookEntryPresenter)
    )
  end

  sig { void }
  def update
    authorize @notebook_entry

    if T.must(@notebook_entry).update(notebook_entry_params)
      redirect_to edit_game_notebook_entry_path(@game, @notebook_entry), notice: "Entry updated."
    else
      @notebook_entry_presenter = T.let(
        NotebookEntryPresenter.new(T.must(@notebook_entry)), T.nilable(NotebookEntryPresenter)
      )
      render :edit, status: :unprocessable_content
    end
  end

  sig { void }
  def destroy
    authorize @notebook_entry
    T.must(@notebook_entry).destroy
    redirect_to game_notebook_entries_path(@game), notice: "Entry deleted."
  end

  sig { void }
  def move
    authorize @notebook_entry, :manage?

    lane_move = NotebookLaneMove.new(params)
    T.must(@notebook_entry).update!(lane_move.attributes)

    # On the board the response swaps the affected lanes in place. Off the
    # board there are no lanes to swap, so say what happened and come back.
    #
    # This branches on an explicit form field, not on the request format:
    # Turbo advertises `text/vnd.turbo-stream.html` for *every* unsafe request,
    # so a `respond_to` format.html branch would be unreachable here.
    if lane_move.standalone?
      redirect_to edit_game_notebook_entry_path(@game, @notebook_entry), notice: "Entry moved."
    else
      render :move, formats: :turbo_stream
    end
  end

  sig { void }
  def promote
    authorize @notebook_entry, :manage?

    page = NotebookEntryPromotion.new(T.must(@notebook_entry)).call
    redirect_to game_page_path(@game, page), notice: "Promoted to a page."
  end

  private

  sig { void }
  def set_game
    @game = T.let(Game.find(params[:game_id]), T.nilable(Game))
  end

  sig { void }
  def set_notebook_entry
    @notebook_entry = T.let(T.must(@game).notebook_entries.find_by!(slug: params[:slug]), T.nilable(NotebookEntry))
  end

  # The notebook's screens render the game nav, which asks whether the viewer
  # may administer the game. Every action here is already GM-only, so the answer
  # is always true today — but the view asks the policy for it rather than
  # hard-coding a literal, so it stays correct when the rule granularizes.
  #
  # Memoized rather than set by a before_action: the actions that render it are
  # not the ones named after it (create and update re-render :new and :edit on
  # validation failure), and a lazily-built presenter cannot be missed off that
  # list.
  sig { returns(GamePresenter) }
  def game_presenter
    @game_presenter ||= T.let(GamePresenter.new(T.must(@game), policy: policy(@game)), T.nilable(GamePresenter))
  end

  sig { params(game: Game).returns(T::Array[NotebookEntry]) }
  def entries_for(game)
    game.notebook_entries.order(:created_at).to_a
  end

  sig { returns(ActionController::Parameters) }
  def notebook_entry_params
    params.require(:notebook_entry).permit(:title, :body)
  end
end
