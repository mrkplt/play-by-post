# typed: strict

class ScenePresenter < BasePresenter
  extend T::Sig

  sig { params(model: Scene, options: T.untyped).void }
  def initialize(model, **options)
    super
  end

  # The wrapped Scene, for the rare place that legitimately needs the raw
  # model: ScenePageAction's sig requires one, and SceneShowPresenter wraps a
  # ScenePresenter rather than a Scene. Everything else goes through a named
  # presenter method instead.
  sig { returns(Scene) }
  def model
    @model
  end

  # Whether this scene has activity since the viewer last logged in — the
  # dashboard/game-view card's attention glow. `hot_scene_ids` is supplied at
  # construction (options[:hot_scene_ids], defaulting to none) rather than
  # computed here, since "last login" is a viewer fact the presenter is not
  # constructed with by every caller.
  sig { returns(T::Boolean) }
  def hot?
    @options.fetch(:hot_scene_ids, Set.new).include?(@model.id)
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
end
