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
    builder = scene_show_builder

    @game_presenter = T.let(GamePresenter.new(game, policy: policy(game), urls: self), T.nilable(GamePresenter))
    @scene_presenter = T.let(builder.scene_presenter, T.nilable(ScenePresenter))
    @scene_navigation_presenter = T.let(builder.navigation_presenter, T.nilable(SceneNavigationPresenter))
    @scene_show = T.let(builder.show_presenter, T.nilable(SceneShowPresenter))
    @scene_posts = T.let(builder.posts_presenter, T.nilable(ScenePostsPresenter))
    @scene_summary_presenter = T.let(builder.summary_presenter, T.nilable(SceneSummaryPresenter))
    T.must(@scene_posts).mark_visited!
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

  # Memoized rather than set by a before_action: #new/#create render the New
  # Scene form (not named after either action) via the scene_form helper
  # method, so there is no single action to hang the assignment on.
  sig { returns(GamePresenter) }
  def game_presenter
    @game_presenter ||= T.let(GamePresenter.new(game, policy: policy(game), urls: self), T.nilable(GamePresenter))
  end

  # Pundit's `policy` is passed as a callable so the builder can resolve a
  # policy per post without reaching for authorization itself.
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

  # Assembles the New Scene / Quick Scene form component for a given scene
  # build. Passed to the template as a `render locals:` value from #new and
  # #create's error re-render, rather than a helper_method memoizing the
  # scene in an ivar — #create needs the SAME (now-invalid) record the save
  # was attempted on, not a fresh `game.scenes.new`, so each action builds it
  # once as a local and threads it through explicitly.
  sig { params(new_scene: Scene).returns(Shared::SceneFormComponent) }
  def build_scene_form(new_scene)
    SceneFormBuilder.new(game, new_scene, params, self).form_component(game_presenter)
  end

  sig { returns(ActionController::Parameters) }
  def scene_params
    params.require(:scene).permit(:title, :private, :parent_scene_id)
  end
end
