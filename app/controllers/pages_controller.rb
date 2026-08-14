# typed: strict

class PagesController < ApplicationController
  extend T::Sig

  before_action :set_game
  before_action :require_game_access!
  before_action :set_page, only: %i[show edit update destroy]
  after_action :verify_authorized

  sig { void }
  def show
    authorize page
    assign_page_presenters(page)
  end

  sig { void }
  def new
    new_page = game.pages.new
    authorize new_page
    assign_page_presenters(new_page)
  end

  sig { void }
  def create
    new_page = game.pages.new(page_params)
    authorize new_page

    if new_page.save
      redirect_to game_page_path(game, new_page), notice: "Page created."
    else
      assign_page_presenters(new_page)
      render :new, status: :unprocessable_content
    end
  end

  sig { void }
  def edit
    authorize page
    assign_page_presenters(page)
  end

  sig { void }
  def update
    authorize page

    if page.update(page_params)
      redirect_to game_page_path(game, page), notice: "Page updated."
    else
      assign_page_presenters(page)
      render :edit, status: :unprocessable_content
    end
  end

  sig { void }
  def destroy
    authorize page
    page.destroy
    redirect_to game_path(game, anchor: "pages"), notice: "Page deleted."
  end

  private

  sig { void }
  def set_game
    @game = T.let(Game.find(params[:game_id]), T.nilable(Game))
  end

  sig { void }
  def set_page
    @page = T.let(game.pages.find_by!(slug: params[:slug]), T.nilable(Page))
  end

  sig { returns(Game) }
  def game
    T.must(@game)
  end

  sig { returns(Page) }
  def page
    T.must(@page)
  end

  sig { void }
  def require_game_access!
    redirect_to root_path, alert: "You do not have access to this game." unless policy(game).view?
  end

  sig { returns(ActionController::Parameters) }
  def page_params
    params.require(:page).permit(:title, :body)
  end

  sig { params(subject: Page).returns(PagePresenter) }
  def page_presenter(subject)
    PagePresenter.new(subject, game_policy: policy(game), page_policy: policy(subject))
  end

  sig { returns(GamePresenter) }
  def game_presenter
    GamePresenter.new(game, policy: policy(game))
  end

  sig { params(subject: Page).void }
  def assign_page_presenters(subject)
    @game_presenter = T.let(game_presenter, T.nilable(GamePresenter))
    @page_presenter = T.let(page_presenter(subject), T.nilable(PagePresenter))
  end
end
