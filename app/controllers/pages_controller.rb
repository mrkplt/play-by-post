# typed: true

class PagesController < ApplicationController
  extend T::Sig

  before_action :set_game
  before_action :require_game_access!
  before_action :set_page, only: %i[show edit update destroy]
  after_action :verify_authorized

  sig { void }
  def show
    authorize @page
    @game_presenter = GamePresenter.new(@game, policy: policy(@game))
    @page_presenter = PagePresenter.new(@page, game_policy: policy(@game), page_policy: policy(@page))
  end

  sig { void }
  def new
    @page = @game.pages.new
    authorize @page
    @game_presenter = GamePresenter.new(@game, policy: policy(@game))
  end

  sig { void }
  def create
    @page = @game.pages.new(page_params)
    authorize @page

    if @page.save
      redirect_to game_page_path(@game, @page), notice: "Page created."
    else
      @game_presenter = GamePresenter.new(@game, policy: policy(@game))
      render :new, status: :unprocessable_content
    end
  end

  sig { void }
  def edit
    authorize @page
    @game_presenter = GamePresenter.new(@game, policy: policy(@game))
  end

  sig { void }
  def update
    authorize @page

    if @page.update(page_params)
      redirect_to game_page_path(@game, @page), notice: "Page updated."
    else
      @game_presenter = GamePresenter.new(@game, policy: policy(@game))
      render :edit, status: :unprocessable_content
    end
  end

  sig { void }
  def destroy
    authorize @page
    @page.destroy
    redirect_to game_path(@game, anchor: "pages"), notice: "Page deleted."
  end

  private

  sig { void }
  def set_game
    @game = Game.find(params[:game_id])
  end

  sig { void }
  def set_page
    @page = @game.pages.find_by!(slug: params[:slug])
  end

  sig { void }
  def require_game_access!
    redirect_to root_path, alert: "You do not have access to this game." unless policy(@game).view?
  end

  sig { returns(ActionController::Parameters) }
  def page_params
    params.require(:page).permit(:title, :body)
  end
end
