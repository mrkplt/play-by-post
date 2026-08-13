# typed: true

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
  # create and update re-render :new/:edit on validation failure, so they need
  # the presenter too.
  before_action :set_game_presenter, only: %i[index new create edit update]
  before_action :set_notebook_entry, only: %i[edit update destroy move promote]
  after_action :verify_authorized

  sig { void }
  def index
    authorize @game.notebook_entries.new, :index?
    @entries = entries_for(@game)
  end

  sig { void }
  def new
    @notebook_entry = @game.notebook_entries.new
    authorize @notebook_entry
  end

  sig { void }
  def create
    @notebook_entry = @game.notebook_entries.new(notebook_entry_params)
    authorize @notebook_entry

    if @notebook_entry.save
      redirect_to game_notebook_entries_path(@game), notice: "Entry created."
    else
      respond_to do |format|
        format.turbo_stream { render :create_failed }
        format.html { render :new, status: :unprocessable_content }
      end
    end
  end

  sig { void }
  def edit
    authorize @notebook_entry
  end

  sig { void }
  def update
    authorize @notebook_entry

    if @notebook_entry.update(notebook_entry_params)
      redirect_to edit_game_notebook_entry_path(@game, @notebook_entry), notice: "Entry updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  sig { void }
  def destroy
    authorize @notebook_entry
    @notebook_entry.destroy
    redirect_to game_notebook_entries_path(@game), notice: "Entry deleted."
  end

  sig { void }
  def move
    authorize @notebook_entry, :manage?

    @notebook_entry.update!(move_params)

    # On the board the response swaps the affected lanes in place. Off the
    # board there are no lanes to swap, so say what happened and come back.
    #
    # This branches on an explicit form field, not on the request format:
    # Turbo advertises `text/vnd.turbo-stream.html` for *every* unsafe request,
    # so a `respond_to` format.html branch would be unreachable here.
    if standalone_move?
      redirect_to edit_game_notebook_entry_path(@game, @notebook_entry), notice: "Entry moved."
    else
      render :move, formats: :turbo_stream
    end
  end

  sig { void }
  def promote
    authorize @notebook_entry, :manage?

    unless @notebook_entry.promoted?
      page = @game.pages.create!(title: @notebook_entry.title, body: @notebook_entry.body)
      @notebook_entry.update!(status: "done", promoted_page: page)
    end

    redirect_to game_page_path(@game, T.must(@notebook_entry.promoted_page)), notice: "Promoted to a page."
  end

  private

  sig { void }
  def set_game
    @game = Game.find(params[:game_id])
  end

  sig { void }
  def set_notebook_entry
    @notebook_entry = @game.notebook_entries.find_by!(slug: params[:slug])
  end

  # The notebook's screens render the game nav, which asks whether the viewer
  # may administer the game. Every action here is already GM-only, so the answer
  # is always true today — but the view asks the policy for it rather than
  # hard-coding a literal, so it stays correct when the rule granularizes.
  sig { void }
  def set_game_presenter
    @game_presenter = GamePresenter.new(@game, T.must(current_user))
  end

  sig { params(game: Game).returns(T::Array[NotebookEntry]) }
  def entries_for(game)
    game.notebook_entries.order(:created_at).to_a
  end

  sig { returns(ActionController::Parameters) }
  def notebook_entry_params
    params.require(:notebook_entry).permit(:title, :body)
  end

  # The lane picker states where it was rendered; only the board can consume a
  # lane-swapping Turbo Stream.
  sig { returns(T::Boolean) }
  def standalone_move?
    params[:response_mode].to_s == "standalone"
  end

  sig { returns(ActionController::Parameters) }
  def move_params
    permitted = params.require(:notebook_entry).permit(:status)
    unless NotebookEntry::STATUSES.include?(permitted[:status])
      raise ActionController::BadRequest, "invalid status"
    end

    permitted
  end
end
