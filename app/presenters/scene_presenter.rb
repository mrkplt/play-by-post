# typed: strict

class ScenePresenter < BasePresenter
  extend T::Sig

  sig { returns(String) }
  def title
    @model.title
  end

  # This scene's child scenes that belong to the given game, wrapped for
  # display — the scene card's "continued in" links show only same-game
  # children. Takes the game explicitly rather than reading @options[:game]
  # so callers that never call #page_action are not forced to construct with
  # a game they do not otherwise need.
  sig { params(game: GamePresenter).returns(T::Array[ScenePresenter]) }
  def child_scenes_in(game)
    @model.child_scenes.select { |c| c.game_id == game.id }.map { |c| ScenePresenter.new(c) }
  end

  sig { returns(T::Boolean) }
  def parent_scene?
    @model.parent_scene.present?
  end

  sig { returns(ScenePresenter) }
  def parent_scene_presenter
    ScenePresenter.new(@model.parent_scene)
  end

  sig { returns(String) }
  def parent_option_label
    @model.resolved? ? "#{@model.title} (Resolved)" : @model.title
  end

  sig { returns(String) }
  def status_label
    @model.resolved? ? "Resolved" : "Active"
  end

  # Pre-computed label/variant pairs for Shared::StatusBadgeRowComponent, for
  # the scene screen's meta row: Private and Resolved, each shown only when
  # true (no badge at all for an ordinary public, active scene).
  sig { returns(T::Array[Shared::StatusBadgeRowComponent::Badge]) }
  def status_badges
    badges = T.let([], T::Array[Shared::StatusBadgeRowComponent::Badge])
    badges << { label: "Private", variant: :yellow } if @model.private?
    badges << { label: "Resolved", variant: :gray } if @model.resolved?
    badges
  end

  # Pre-computed label/variant pairs for Shared::StatusBadgeRowComponent, for
  # the scene tree row: always a status badge (Active/Resolved), plus Private
  # when set. The presenter picks the symbolic Ui::BadgeComponent variant so
  # the component never inspects the model directly.
  sig { returns(T::Array[Shared::StatusBadgeRowComponent::Badge]) }
  def tree_status_badges
    badges = T.let(
      [ { label: status_label, variant: @model.resolved? ? :gray : :green } ],
      T::Array[Shared::StatusBadgeRowComponent::Badge]
    )
    badges << { label: "Private", variant: :yellow } if @model.private?
    badges
  end

  sig { returns(String) }
  def participant_names
    @model.scene_participants
      .includes(:character, :user)
      .map(&:display_name)
      .join(", ")
  end

  # "N participants" — the only meta a scene card shows in the redesign.
  sig { returns(String) }
  def participant_summary
    count = @model.scene_participants.count
    "#{count} #{count == 1 ? 'participant' : 'participants'}"
  end

  sig { returns(String) }
  def formatted_created_at
    @model.created_at.strftime("%b %-d, %Y %l:%M%P")
  end

  sig { returns(String) }
  def tree_row_css_class
    @model.resolved? ? "text-slate-500" : "font-semibold"
  end

  sig { returns(String) }
  def tree_link_css_class
    @model.resolved? ? "text-slate-500" : ""
  end

  sig { returns(ActiveStorage::VariantWithRecord) }
  def banner_image
    @model.image.variant(resize_to_limit: [ 1200, nil ], format: :jpeg, quality: 85)
  end

  # Whether this viewer may post into the scene right now: the post policy allows
  # it and the scene is still open. Keeps the composer's visibility sourced from
  # the same policy PostsController authorizes with. The policy is supplied at
  # construction (options[:post_policy]) instead of built here, so the
  # presenter never constructs authorization itself.
  sig { returns(T::Boolean) }
  def can_post?
    @options.fetch(:post_policy).create? && !@model.resolved?
  end

  # The mute/unmute control's label, derived from the viewer's current
  # notification-preference state.
  sig { params(muted: T::Boolean).returns(String) }
  def mute_toggle_label(muted)
    muted ? "Unmute notifications" : "Mute notifications"
  end

  # The draft worth surfacing as a recovery notice: the composer disappears
  # once a scene resolves, so a leftover draft is only worth recovering in
  # that state. `draft` is whatever the controller found (or nil).
  sig { params(draft: T.nilable(Post)).returns(T.nilable(Post)) }
  def recoverable_draft(draft)
    @model.resolved? ? draft : nil
  end

  # The scene screen's footer page-action, resolved to a render-ready
  # label/href/method triple; ScenePageAction owns the rule and the shape.
  # The game and url_helpers come from construction, so the view reads a
  # finished href rather than handing the presenter a route helper.
  sig do
    params(can_manage: T::Boolean, is_participant: T::Boolean,
           membership: T.nilable(GameMember))
      .returns(T.nilable(ScenePageAction::Resolved))
  end
  def page_action(can_manage:, is_participant:, membership:)
    ScenePageAction.resolved_for(
      scene: @model,
      viewer: ScenePageAction::Viewer.new(
        can_manage: can_manage, is_participant: is_participant, membership: membership
      ),
      route_args: ScenePageAction::RouteArgs.new(
        urls: @options[:urls], game: @options[:game]
      )
    )
  end
end
