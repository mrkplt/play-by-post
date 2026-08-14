# typed: strict

class ScenesController < ApplicationController
  extend T::Sig
  include ImageAttachable

  before_action :set_game
  before_action :require_game_access!
  before_action :set_scene, only: %i[show resolve toggle_notification_preference]
  after_action :verify_authorized, except: :index

  helper_method :scene_form, :game_presenter

  sig { void }
  def index
    all_scenes = ScenePolicy::Scope.new(current_user, game).resolve
      .includes(:parent_scene, :child_scenes, scene_participants: [ :character, :user ])
      .order(created_at: :asc)
      .to_a

    scene_index = all_scenes.index_by(&:id)
    roots = all_scenes.select { |s| s.parent_scene_id.nil? || scene_index[s.parent_scene_id].nil? }

    @scene_tree_presenter = T.let(
      SceneTreePresenter.new(roots.map { |root| build_tree(root, scene_index, all_scenes) }),
      T.nilable(SceneTreePresenter)
    )
    @game_presenter = T.let(GamePresenter.new(game, policy: policy(@game)), T.nilable(GamePresenter))
  end

  sig { void }
  def new
    authorize new_scene
  end

  sig { void }
  def create
    authorize new_scene
    new_scene.assign_attributes(permitted_attributes(new_scene))
    attach_uploaded_image(new_scene, @game, param_key: :scene)

    if new_scene.save
      add_participants(new_scene)
      notify_new_scene(new_scene)
      redirect_to game_scene_path(game, new_scene), notice: "Scene created."
    else
      render :new, status: :unprocessable_content
    end
  end

  sig { void }
  def show
    authorize @scene
    @game_presenter = T.let(GamePresenter.new(game, policy: policy(@game)), T.nilable(GamePresenter))
    @scene_presenter = T.let(ScenePresenter.new(scene, game: game, urls: self), T.nilable(ScenePresenter))
    @scene_show = T.let(build_scene_show_presenter, T.nilable(SceneShowPresenter))
    @scene_posts = T.let(build_scene_posts_presenter, T.nilable(ScenePostsPresenter))
    @scene_summary_presenter = T.let(build_scene_summary_presenter, T.nilable(SceneSummaryPresenter))
    T.must(@scene_posts).mark_visited!
  end

  sig { void }
  def toggle_notification_preference
    authorize @scene, :show?
    NotificationPreference.toggle!(scene, current_user)
    redirect_to game_scene_path(game, scene),
      notice: NotificationPreference.muted?(scene, current_user) ? "Notifications muted for this scene." : "Notifications enabled for this scene."
  end

  sig { void }
  def resolve
    authorize @scene

    if scene.resolved?
      redirect_to game_scene_path(game, scene), alert: "Scene is already resolved."
      return
    end

    scene.update!(resolved_at: Time.current, resolution: params[:resolution])
    notify_scene_resolved
    SceneSummaryJob.perform_later(scene.id) if game.ai_summaries_enabled?
    redirect_to game_scene_path(game, scene), notice: "Scene resolved."
  end

  private

  sig { void }
  def set_game
    @game = T.let(Game.find(params[:game_id]), T.nilable(Game))
  end

  sig { void }
  def set_scene
    @scene = T.let(game.scenes.find(params[:id]), T.nilable(Scene))
    check_scene_visibility!
  end

  # @game/@scene are always populated by their before_actions for every
  # action that reads them (declared T.nilable only because Sorbet strict
  # requires ivars assigned outside `initialize` to admit nil).
  sig { returns(Game) }
  def game
    T.must(@game)
  end

  sig { returns(Scene) }
  def scene
    T.must(@scene)
  end

  # Memoized rather than set by a before_action: #new/#create render the New
  # Scene form (not named after either action) via the scene_form helper
  # method, so there is no single action to hang the assignment on.
  sig { returns(GamePresenter) }
  def game_presenter
    @game_presenter ||= T.let(GamePresenter.new(game, policy: policy(@game)), T.nilable(GamePresenter))
  end

  sig { returns(SceneShowPresenter) }
  def build_scene_show_presenter
    SceneShowPresenter.new(T.must(@scene_presenter), game: game, urls: self, current_user: current_user)
  end

  sig { returns(ScenePostsPresenter) }
  def build_scene_posts_presenter
    ScenePostsPresenter.new(
      T.must(@scene_presenter), game: game, urls: self, current_user: current_user,
      post_policy: PostPolicy.new(current_user, scene.posts.new),
      post_presenters: build_post_presenters
    )
  end

  # Published posts wrapped for display, each with its own Pundit-resolved
  # policy — built here (not in the presenter) because only the controller
  # has policy(post) (R2: presenters never construct authorization).
  sig { returns(T::Array[PostPresenter]) }
  def build_post_presenters
    posts = scene.posts.published.includes(:user).order(:created_at).to_a
    participants = scene.scene_participants.includes(:character, :user).to_a
    posts.map do |post|
      PostPresenter.new(
        post, scene_participants: participants, game: game, scene: scene,
        urls: self, policy: policy(post)
      )
    end
  end

  # nil when the scene has no summary yet — the view's own condition (scene
  # resolved? && summary present?) reads @scene_summary_presenter directly
  # rather than this controller building the policy speculatively.
  sig { returns(T.nilable(SceneSummaryPresenter)) }
  def build_scene_summary_presenter
    summary = scene.scene_summary
    return nil unless summary

    SceneSummaryPresenter.new(summary, game: game, urls: self, policy: SceneSummaryPolicy.new(current_user, summary))
  end

  sig { void }
  def check_scene_visibility!
    redirect_to game_path(@game), alert: "You do not have access to this scene." unless policy(@scene).visible?
  end

  sig { void }
  def require_game_access!
    redirect_to root_path, alert: "You do not have access to this game." unless policy(@game).view?
  end

  # The scene #new/#create build and validate against — memoized so the
  # error-path re-render in #create sees the same (now-invalid) record the
  # save was attempted on, not a fresh one.
  sig { returns(Scene) }
  def new_scene
    @new_scene ||= T.let(game.scenes.new, T.nilable(Scene))
  end

  # Assembles the New Scene / Quick Scene form component from the current
  # request. Exposed to the view via helper_method so #new and #create's
  # error re-render both present it without it being a controller ivar.
  sig { returns(Shared::SceneFormComponent) }
  def scene_form
    SceneFormBuilder.new(game, new_scene, params, self).form_component(game_presenter)
  end

  sig { params(new_scene: Scene).void }
  def notify_new_scene(new_scene)
    new_scene.users.where.not(id: current_user.id).find_each do |recipient|
      next if NotificationPreference.muted?(new_scene, recipient)
      NotificationMailer.new_scene(new_scene, recipient).deliver_later
    end
  end

  sig { void }
  def notify_scene_resolved
    scene.users.each do |recipient|
      next if NotificationPreference.muted?(scene, recipient)
      NotificationMailer.scene_resolved(scene, recipient).deliver_later
    end
  end

  sig { params(new_scene: Scene).void }
  def add_participants(new_scene)
    gm = T.must(game.game_master)

    # Always add the GM as a user-only (no character) participant
    new_scene.scene_participants.find_or_create_by!(user_id: gm.id)

    # Add each selected character, deriving user from character.user
    Array(params[:character_ids]).map(&:to_i).each do |cid|
      character = game.characters.find_by(id: cid)
      next unless character
      new_scene.scene_participants.find_or_create_by!(user_id: character.user_id) do |sp|
        sp.character = character
      end
    end
  end

  sig do
    params(
      node_scene: Scene, scene_index: T::Hash[Integer, Scene], all_scenes: T::Array[Scene]
    ).returns(Shared::TreeNodeComponent::Node)
  end
  def build_tree(node_scene, scene_index, all_scenes)
    children = all_scenes
      .select { |s| s.parent_scene_id == node_scene.id }
      .sort_by(&:created_at)
    Shared::TreeNodeComponent::Node.new(
      scene_presenter: ScenePresenter.new(node_scene),
      children: children.map { |c| build_tree(c, scene_index, all_scenes) }
    )
  end

  sig { returns(ActionController::Parameters) }
  def scene_params
    params.require(:scene).permit(:title, :private, :parent_scene_id)
  end
end
