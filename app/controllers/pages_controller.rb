# typed: strict

class PagesController < ApplicationController
  extend T::Sig

  before_action :require_game_access!
  after_action :verify_authorized

  sig { void }
  def show
    subject = page
    authorize subject
    assign_page_presenters(subject)
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
    subject = page
    authorize subject
    assign_page_presenters(subject)
  end

  # Saving keeps the writer on the edit screen — a page is long-form markdown
  # and being bounced to the show screen on every save loses their place.
  sig { void }
  def update
    subject = page
    authorize subject
    outcome = SaveOutcome.for(subject.update(page_params), "page")
    assign_page_presenters(subject)
    InPlaceSave.new(self, outcome: outcome, forward_to: game_page_path(game, subject)).respond
  end

  sig { void }
  def destroy
    subject = page
    authorize subject
    subject.destroy
    redirect_to game_path(game, anchor: "pages"), notice: "Page deleted."
  end

  private

  # No before_action ivar for either lookup: neither is read by a template
  # (templates hold only @game_presenter/@page_presenter), so under
  # `# typed: strict` an ivar here would itself be a raw model reaching the
  # view layer's boundary — Sorbet requires a T.let on every ivar write under
  # `strict`, and the gate reads that declared type. #game re-resolves from
  # params on every call; #page is called once per action into a local
  # (`subject`) rather than re-called, because #update mutates that instance
  # with validation errors that a fresh DB lookup would lose.
  sig { returns(Game) }
  def game
    Game.find_by!(slug: params[:game_id])
  end

  sig { returns(Page) }
  def page
    game.pages.find_by!(slug: params[:slug])
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
    PagePresenter.new(subject, game_policy: policy(game), page_policy: policy(subject), game: game, urls: self)
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
