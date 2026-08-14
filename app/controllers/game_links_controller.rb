# typed: true

class GameLinksController < ApplicationController
  extend T::Sig

  before_action :set_game
  before_action :require_game_access!
  before_action :set_game_link, only: %i[edit update destroy]
  after_action :verify_authorized

  sig { void }
  def index
    @game_link = @game.game_links.new
    authorize @game_link
    @game_presenter = GamePresenter.new(@game, policy: policy(@game))
    @game_links = @game.game_links.order(created_at: :desc).to_a
      .map { |gl| GameLinkPresenter.new(gl, game: @game, urls: self) }
  end

  sig { void }
  def new
    @game_link = @game.game_links.new
    authorize @game_link
    @game_presenter = GamePresenter.new(@game, policy: policy(@game))
    @game_link_presenter = GameLinkPresenter.new(@game_link, game: @game, urls: self)
  end

  sig { void }
  def create
    @game_link = @game.game_links.new(game_link_params)
    authorize @game_link

    if @game_link.save
      redirect_to game_game_links_path(@game), notice: "Link added."
    else
      @game_presenter = GamePresenter.new(@game, policy: policy(@game))
      @game_link_presenter = GameLinkPresenter.new(@game_link, game: @game, urls: self)
      render :new, status: :unprocessable_content
    end
  end

  sig { void }
  def edit
    authorize @game_link
    @game_presenter = GamePresenter.new(@game, policy: policy(@game))
    @game_link_presenter = GameLinkPresenter.new(@game_link, game: @game, urls: self)
  end

  sig { void }
  def update
    authorize @game_link

    if @game_link.update(game_link_params)
      redirect_to game_game_links_path(@game), notice: "Link updated."
    else
      @game_presenter = GamePresenter.new(@game, policy: policy(@game))
      @game_link_presenter = GameLinkPresenter.new(@game_link, game: @game, urls: self)
      render :edit, status: :unprocessable_content
    end
  end

  sig { void }
  def destroy
    authorize @game_link
    @game_link.destroy
    redirect_to game_game_links_path(@game), notice: "Link deleted."
  end

  private

  sig { void }
  def set_game
    @game = Game.find(params[:game_id])
  end

  sig { void }
  def set_game_link
    @game_link = @game.game_links.find(params[:id])
  end

  sig { void }
  def require_game_access!
    redirect_to root_path, alert: "You do not have access to this game." unless policy(@game).view?
  end

  sig { returns(ActionController::Parameters) }
  def game_link_params
    params.require(:game_link).permit(:url, :description)
  end
end
