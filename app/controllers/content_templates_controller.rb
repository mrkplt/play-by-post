# typed: strict

class ContentTemplatesController < ApplicationController
  extend T::Sig
  include InPlaceRender

  before_action :require_game_access!
  after_action :verify_authorized

  sig { void }
  def index
    templates = game.content_templates
    authorize templates.new, :index?
    @game_presenter = T.let(game_presenter, T.nilable(GamePresenter))
    @content_template_presenters = T.let(
      templates.order(:content_type).to_a.map { |template| content_template_presenter(template) },
      T.nilable(T::Array[ContentTemplatePresenter])
    )
  end

  sig { void }
  def new
    new_template = game.content_templates.new
    authorize new_template
    assign_form_presenters(new_template)
  end

  sig { void }
  def create
    new_template = game.content_templates.new(content_template_params)
    authorize new_template

    if new_template.save
      redirect_to game_content_templates_path(game), notice: "Template saved."
    else
      assign_form_presenters(new_template)
      render :new, status: :unprocessable_content
    end
  end

  sig { void }
  def edit
    authorize content_template
    assign_form_presenters(content_template)
  end

  sig { void }
  def update
    authorize content_template

    if content_template.update(content_template_params)
      redirect_to game_content_templates_path(game), notice: "Template updated."
    else
      assign_form_presenters(content_template)
      render :edit, status: :unprocessable_content
    end
  end

  sig { void }
  def destroy
    authorize content_template
    content_template.destroy
    flash_now(notice: "Template deleted.")
    render turbo_stream: [ turbo_stream.replace(Shared::ContentTemplatesListComponent::DOM_ID, templates_list), toast_stream ]
  end

  private

  sig { params(template: ContentTemplate).void }
  def assign_form_presenters(template)
    @game_presenter = T.let(game_presenter, T.nilable(GamePresenter))
    @content_template_presenter = T.let(content_template_presenter(template), T.nilable(ContentTemplatePresenter))
  end

  sig { returns(Game) }
  def game
    Game.find_by!(slug: params[:game_id])
  end

  sig { returns(ContentTemplate) }
  def content_template
    game.content_templates.find(params[:id])
  end

  sig { returns(Shared::ContentTemplatesListComponent) }
  def templates_list
    Shared::ContentTemplatesListComponent.new(
      game: game_presenter,
      templates: game.content_templates.order(:content_type).map { |template| content_template_presenter(template) }
    )
  end

  sig { void }
  def require_game_access!
    redirect_to root_path, alert: "You do not have access to this game." unless policy(game).view?
  end

  sig { returns(ActionController::Parameters) }
  def content_template_params
    params.require(:content_template).permit(:content_type, :body)
  end

  sig { params(template: ContentTemplate).returns(ContentTemplatePresenter) }
  def content_template_presenter(template)
    ContentTemplatePresenter.new(template, game: game, urls: self)
  end

  sig { returns(GamePresenter) }
  def game_presenter
    GamePresenter.new(game, policy: policy(game))
  end
end
