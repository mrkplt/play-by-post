# typed: strict

class GameLinksController < ApplicationController
  extend T::Sig

  before_action :set_game
  before_action :require_game_access!
  before_action :set_game_link, only: %i[edit update destroy]
  after_action :verify_authorized

  sig { void }
  def index
    links = game.game_links
    authorize links.new
    @game_presenter = T.let(game_presenter, T.nilable(GamePresenter))
    @game_links = T.let(
      links.order(created_at: :desc).to_a.map { |gl| game_link_presenter(gl) },
      T.nilable(T::Array[GameLinkPresenter])
    )
  end

  sig { void }
  def new
    new_link = game.game_links.new
    authorize new_link
    assign_form_presenters(new_link)
  end

  sig { void }
  def create
    new_link = game.game_links.new(game_link_params)
    authorize new_link

    if new_link.save
      redirect_to game_game_links_path(game), notice: "Link added."
    else
      assign_form_presenters(new_link)
      render :new, status: :unprocessable_content
    end
  end

  sig { void }
  def edit
    authorize game_link
    assign_form_presenters(game_link)
  end

  sig { void }
  def update
    authorize game_link

    if game_link.update(game_link_params)
      redirect_to game_game_links_path(game), notice: "Link updated."
    else
      assign_form_presenters(game_link)
      render :edit, status: :unprocessable_content
    end
  end

  sig { void }
  def destroy
    authorize game_link
    game_link.destroy
    redirect_to game_game_links_path(game), notice: "Link deleted."
  end

  private

  sig { params(link: GameLink).void }
  def assign_form_presenters(link)
    @game_presenter = T.let(game_presenter, T.nilable(GamePresenter))
    @game_link_presenter = T.let(game_link_presenter(link), T.nilable(GameLinkPresenter))
  end

  sig { void }
  def set_game
    @game = T.let(Game.find(params[:game_id]), T.nilable(Game))
  end

  sig { void }
  def set_game_link
    @game_link = T.let(game.game_links.find(params[:id]), T.nilable(GameLink))
  end

  sig { returns(Game) }
  def game
    T.must(@game)
  end

  sig { returns(GameLink) }
  def game_link
    T.must(@game_link)
  end

  sig { void }
  def require_game_access!
    redirect_to root_path, alert: "You do not have access to this game." unless policy(game).view?
  end

  sig { returns(ActionController::Parameters) }
  def game_link_params
    params.require(:game_link).permit(:url, :description)
  end

  sig { params(link: GameLink).returns(GameLinkPresenter) }
  def game_link_presenter(link)
    GameLinkPresenter.new(link, game: game, urls: self)
  end

  sig { returns(GamePresenter) }
  def game_presenter
    GamePresenter.new(game, policy: policy(game))
  end
end
