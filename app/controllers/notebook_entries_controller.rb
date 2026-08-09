# typed: true

# The Campaign Notebook: a GM-only kanban of short entries (new / expand /
# done / discard) that can be "promoted" into a full game Page. Unlike
# PagesController, every action here is GM-only — there is no read path for
# other members.
class NotebookEntriesController < ApplicationController
  extend T::Sig

  before_action :set_game
  before_action :require_gm!
  before_action :set_notebook_entry, only: %i[show edit update destroy move promote]
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
      redirect_to game_notebook_entry_path(@game, @notebook_entry), notice: "Entry created."
    else
      respond_to do |format|
        format.turbo_stream { render :create_failed }
        format.html { render :new, status: :unprocessable_content }
      end
    end
  end

  sig { void }
  def show
    authorize @notebook_entry
  end

  sig { void }
  def edit
    authorize @notebook_entry

    respond_to do |format|
      format.turbo_stream
      format.html
    end
  end

  sig { void }
  def update
    authorize @notebook_entry

    if @notebook_entry.update(notebook_entry_params)
      if inline_request?
        render :update
      else
        redirect_to game_notebook_entry_path(@game, @notebook_entry), notice: "Entry updated."
      end
    elsif inline_request?
      render :update_failed
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
    authorize @notebook_entry, :update?
    @notebook_entry.update!(move_params)

    respond_to do |format|
      format.turbo_stream
    end
  end

  sig { void }
  def promote
    authorize @notebook_entry, :update?

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

  sig { void }
  def require_gm!
    unless policy(@game).update?
      redirect_to game_path(@game), alert: "Only the GM can access the notebook."
    end
  end

  sig { params(game: Game).returns(T::Array[NotebookEntry]) }
  def entries_for(game)
    game.notebook_entries.order(:created_at).to_a
  end

  sig { returns(T::Boolean) }
  def inline_request?
    params[:inline].present?
  end

  sig { returns(ActionController::Parameters) }
  def notebook_entry_params
    params.require(:notebook_entry).permit(:title, :body)
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
