# typed: strict

class GameLinksController < ApplicationController
  extend T::Sig
  include InPlaceRender

  before_action :require_game_access!
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
    new_link = game.game_links.new(game_link_params.merge(created_by: current_user))
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

  # Delete happens on the links index — re-render the list in place (rows and
  # empty-state follow) plus a toast, no full reload. flash.now, not flash.
  sig { void }
  def destroy
    authorize game_link
    game_link.destroy
    flash_now(notice: "Link deleted.")
    render turbo_stream: [ turbo_stream.replace(Shared::GameLinksListComponent::DOM_ID, links_list), toast_stream ]
  end

  private

  # The list re-rendered in place after a delete. Only #destroy calls this, and
  # it has already authorized deleting a link — which requires the actor be a
  # contributor (the GM, or a player deleting their own while contributions are
  # on) — so can_contribute is true by construction, no need to re-ask the
  # policy. Each row's Edit/Delete still follows its own link's policy via the
  # presenter (Fizzy #18).
  sig { returns(Shared::GameLinksListComponent) }
  def links_list
    Shared::GameLinksListComponent.new(
      game: game_presenter,
      game_links: game.game_links.order(created_at: :desc).map { |gl| game_link_presenter(gl) },
      can_contribute: true
    )
  end

  sig { params(link: GameLink).void }
  def assign_form_presenters(link)
    @game_presenter = T.let(game_presenter, T.nilable(GamePresenter))
    @game_link_presenter = T.let(game_link_presenter(link), T.nilable(GameLinkPresenter))
  end

  # Looked up on demand rather than cached in a before_action ivar: no
  # template reads it directly (only @game_presenter's output does), so
  # nothing needs it to persist as request state.
  sig { returns(Game) }
  def game
    Game.find_by!(slug: params[:game_id])
  end

  # Looked up on demand rather than cached in a before_action ivar: no
  # template reads it directly (only game_link_presenter's output does), so
  # there is nothing that needs it to persist across the request as state.
  sig { returns(GameLink) }
  def game_link
    game.game_links.find(params[:id])
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
    GameLinkPresenter.new(link, game: game, urls: self, link_policy: policy(link))
  end

  sig { returns(GamePresenter) }
  def game_presenter
    GamePresenter.new(game, policy: policy(game))
  end
end
