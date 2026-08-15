# typed: strict

class ScenesController < ApplicationController
  extend T::Sig
  include ImageAttachable
  include SceneScoped

  before_action :require_game_access!
  before_action :check_scene_visibility!, only: %i[show resolve toggle_notification_preference]
  after_action :verify_authorized, except: :index

  helper_method :game_presenter

  sig { void }
  def index
    tree = SceneTreeBuilder.for(current_user, game).call

    @scene_tree_presenter = T.let(tree, T.nilable(SceneTreePresenter))
    @game_presenter = T.let(GamePresenter.new(game, policy: policy(game), urls: self), T.nilable(GamePresenter))
    @game_routes = T.let(GameRoutesPresenter.new(T.must(@game_presenter), urls: self), T.nilable(GameRoutesPresenter))
  end

  sig { void }
  def new
    new_scene = game.scenes.new
    authorize new_scene
    render locals: { scene_form: build_scene_form(new_scene) }
  end

  sig { void }
  def create
    new_scene = game.scenes.new
    authorize new_scene
    new_scene.assign_attributes(permitted_attributes(new_scene))
    attach_uploaded_image(new_scene, game, param_key: :scene)

    if new_scene.save
      SceneParticipantSeeder.new(new_scene, game).call(params[:character_ids])
      SceneNotifier.new(new_scene).created(current_user)
      redirect_to game_scene_path(game, new_scene), notice: "Scene created."
    else
      render :new, status: :unprocessable_content, locals: { scene_form: build_scene_form(new_scene) }
    end
  end

  sig { void }
  def show
    authorize scene
    screen = scene_show_builder.screen(game_presenter)

    @scene_screen = T.let(screen, T.nilable(SceneScreenPresenter))
    screen.posts.mark_visited!
  end

  sig { void }
  def toggle_notification_preference
    authorize scene, :show?
    NotificationPreference.toggle!(scene, current_user)
    redirect_to game_scene_path(game, scene),
      notice: NotificationPreference.muted?(scene, current_user) ? "Notifications muted for this scene." : "Notifications enabled for this scene."
  end

  sig { void }
  def resolve
    authorize scene
    message = if SceneResolution.new(scene).call(params[:resolution])
      { notice: "Scene resolved." }
    else
      { alert: "Scene is already resolved." }
    end

    redirect_to game_scene_path(game, scene), **message
  end

  private

  # Memoized, not a before_action: #new/#create render a form not named after
  # either action, so there is no single action to hang the assignment on.
  sig { returns(GamePresenter) }
  def game_presenter
    @game_presenter ||= T.let(GamePresenter.new(game, policy: policy(game), urls: self), T.nilable(GamePresenter))
  end

  sig { returns(SceneShowBuilder) }
  def scene_show_builder
    context = SceneShowBuilder::Context.new(
      urls: self, current_user: current_user, policies: ->(record) { policy(record) }
    )

    SceneShowBuilder.new(scene, game: game, context: context)
  end

  sig { void }
  def check_scene_visibility!
    redirect_to game_path(game), alert: "You do not have access to this scene." unless policy(scene).visible?
  end

  sig { void }
  def require_game_access!
    redirect_to root_path, alert: "You do not have access to this game." unless policy(game).view?
  end

  # Threaded as a `render locals:` value rather than memoized in an ivar:
  # #create must re-render the SAME invalid record the save was attempted on.
  sig { params(new_scene: Scene).returns(Shared::SceneFormComponent) }
  def build_scene_form(new_scene)
    SceneFormBuilder.new(game, new_scene, params, self).form_component(game_presenter)
  end

  sig { returns(ActionController::Parameters) }
  def scene_params
    params.require(:scene).permit(:title, :private, :parent_scene_id)
  end
end
