# typed: strict

class ScenesController < ApplicationController
  extend T::Sig

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
    attach_image(new_scene)

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
    @scene_presenter = T.let(build_scene_presenter, T.nilable(ScenePresenter))
    @scene_summary_presenter = T.let(build_scene_summary_presenter, T.nilable(SceneSummaryPresenter))
    T.must(@scene_presenter).mark_visited!
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

  sig { returns(ScenePresenter) }
  def build_scene_presenter
    ScenePresenter.new(
      scene, game: game, urls: self, current_user: current_user,
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
    Shared::SceneFormComponent.new(
      game: game_presenter,
      scene: ScenePresenter.new(new_scene),
      players_with_characters: active_players_with_characters,
      parent_options: parent_scene_select_options,
      quick: params[:quick].present?,
      selected_character_ids: selected_character_ids,
      selected_parent_scene_id: params[:parent_scene_id]&.to_s,
      back_href: scene_form_back_href
    )
  end

  # Parent-scene dropdown pairs: [label, id]. Built from raw scenes so Sorbet
  # keeps the id typed while ScenePresenter supplies the display label.
  sig { returns(T::Array[[ String, Integer ]]) }
  def parent_scene_select_options
    parent_scene_options.map { |s| [ ScenePresenter.new(s).parent_option_label, s.id ] }
  end

  # Characters that should start checked: any resubmitted in params, unioned
  # with any already attached to the scene (present when re-rendering an edit).
  sig { returns(T::Array[String]) }
  def selected_character_ids
    from_params = Array(params[:character_ids]).map(&:to_s)
    from_params | new_scene.scene_participants.filter_map { |sp| sp.character_id&.to_s }
  end

  sig { returns(String) }
  def scene_form_back_href
    if params[:parent_scene_id].present?
      game_scene_path(game, params[:parent_scene_id])
    else
      game_path(game)
    end
  end

  # Returns one ScenePlayerPresenter per active player, each carrying its own
  # active characters (empty array when the player has none).
  sig { returns(T::Array[ScenePlayerPresenter]) }
  def active_players_with_characters
    players = game.users.joins(:game_members)
      .where(game_members: { game: game, role: "player", status: "active" })
      .order("user_profiles.display_name")
      .joins("LEFT JOIN user_profiles ON user_profiles.user_id = users.id")

    characters_by_user = game.characters.active
      .joins("INNER JOIN game_members ON game_members.user_id = characters.user_id AND game_members.game_id = #{game.id}")
      .where(game_members: { role: "player", status: "active" })
      .order(:name)
      .group_by(&:user_id)

    players.map { |user| ScenePlayerPresenter.new(user, characters: characters_by_user.fetch(user.id, [])) }
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

  sig { returns(T::Array[Scene]) }
  def parent_scene_options
    active = game.scenes.active.order(created_at: :desc).to_a
    recent_resolved = game.scenes.resolved.order(resolved_at: :desc).limit(3).to_a
    (active + recent_resolved)
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

  sig { params(scene: Scene).void }
  def attach_image(scene)
    image = params.dig(:scene, :image)
    return unless image.respond_to?(:original_filename)

    AttachmentUploader.attach(
      attachment: scene.image,
      attachable: image,
      kind: "scene_image",
      user: current_user,
      game: @game,
      original_filename: image.original_filename
    )
  end
end
