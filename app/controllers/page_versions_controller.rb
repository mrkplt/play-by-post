# typed: strict

class PageVersionsController < ApplicationController
  extend T::Sig

  before_action :require_game_access!
  after_action :verify_authorized

  sig { void }
  def show
    authorize version
    @version_presenter = T.let(PageVersionPresenter.new(version), T.nilable(PageVersionPresenter))
    @page_presenter = T.let(page_presenter, T.nilable(PagePresenter))
    @game_presenter = T.let(GamePresenter.new(game, policy: policy(game)), T.nilable(GamePresenter))
  end

  private

  # No before_action ivar: the route-nested records (game -> page -> version)
  # are controller-internal plumbing, never read by a template, so under
  # `# typed: strict` an ivar holding them would be a raw model at the view
  # boundary. Each accessor re-resolves from params; #show is the only action.
  sig { returns(Game) }
  def game
    Game.find_by!(slug: params[:game_id])
  end

  sig { returns(Page) }
  def page
    game.pages.find_by!(slug: params[:page_slug])
  end

  sig { returns(PageVersion) }
  def version
    page.page_versions.find(params[:id])
  end

  sig { returns(PagePresenter) }
  def page_presenter
    PagePresenter.new(page, game_policy: policy(game), page_policy: policy(page), game: game, urls: self)
  end

  sig { void }
  def require_game_access!
    redirect_to root_path, alert: "You do not have access to this game." unless policy(game).view?
  end
end
