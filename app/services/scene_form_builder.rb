# typed: strict
# frozen_string_literal: true

# Assembles the New Scene / Quick Scene form (ScenesController#scene_form) and
# its supporting data: the parent-scene dropdown, the checked-character set,
# and the back-link target. Takes the game/params/url_helpers/policy the
# controller already has rather than looking any of them up — presenters and
# their builders never construct authorization (R2).
class SceneFormBuilder
  extend T::Sig

  sig { params(game: Game, new_scene: Scene, params: ActionController::Parameters, urls: T.untyped).void }
  def initialize(game, new_scene, params, urls)
    @game = game
    @new_scene = new_scene
    @params = params
    @urls = urls
  end

  sig { params(game_presenter: GamePresenter).returns(Shared::SceneFormComponent) }
  def form_component(game_presenter)
    Shared::SceneFormComponent.new(
      game: game_presenter,
      scene: ScenePresenter.new(@new_scene),
      selection: Shared::SceneFormComponent::Selection.new(
        quick: @params[:quick].present?,
        back_href: back_href,
        players_with_characters: active_players_with_characters,
        parent_options: parent_scene_select_options,
        selected_character_ids: selected_character_ids,
        selected_parent_scene_id: @params[:parent_scene_id]&.to_s
      )
    )
  end

  private

  # Parent-scene dropdown pairs: [label, id]. Built from raw scenes so Sorbet
  # keeps the id typed while ScenePresenter supplies the display label.
  sig { returns(T::Array[[ String, Integer ]]) }
  def parent_scene_select_options
    parent_scene_options.map { |scene| [ ScenePresenter.new(scene).parent_option_label, scene.id ] }
  end

  sig { returns(T::Array[Scene]) }
  def parent_scene_options
    active_parent_scenes + recent_resolved_parent_scenes
  end

  sig { returns(T::Array[Scene]) }
  def active_parent_scenes
    @game.scenes.active.order(created_at: :desc).to_a
  end

  sig { returns(T::Array[Scene]) }
  def recent_resolved_parent_scenes
    @game.scenes.resolved.order(resolved_at: :desc).limit(3).to_a
  end

  # Characters that should start checked: any resubmitted in params, unioned
  # with any already attached to the scene (present when re-rendering an edit).
  sig { returns(T::Array[String]) }
  def selected_character_ids
    from_params = Array(@params[:character_ids]).map(&:to_s)
    from_params | @new_scene.scene_participants.filter_map { |sp| sp.character_id&.to_s }
  end

  sig { returns(String) }
  def back_href
    parent_scene_id = @params[:parent_scene_id]
    if parent_scene_id.present?
      @urls.game_scene_path(@game, parent_scene_id)
    else
      @urls.game_path(@game)
    end
  end

  # Returns one ScenePlayerPresenter per active player, each carrying its own
  # active characters (empty array when the player has none).
  sig { returns(T::Array[ScenePlayerPresenter]) }
  def active_players_with_characters
    players = @game.users.joins(:game_members)
      .where(game_members: { game: @game, role: "player", status: "active" })
      .order("user_profiles.display_name")
      .joins("LEFT JOIN user_profiles ON user_profiles.user_id = users.id")

    characters_by_user = @game.characters.active
      .joins("INNER JOIN game_members ON game_members.user_id = characters.user_id AND game_members.game_id = #{@game.id}")
      .where(game_members: { role: "player", status: "active" })
      .order(:name)
      .group_by(&:user_id)

    players.map { |user| ScenePlayerPresenter.new(user, characters: characters_by_user.fetch(user.id, [])) }
  end
end
