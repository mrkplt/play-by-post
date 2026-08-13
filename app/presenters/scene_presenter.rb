# typed: strict

class ScenePresenter < BasePresenter
  extend T::Sig

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
  # the same policy PostsController authorizes with, without a controller ivar.
  sig { params(user: User).returns(T::Boolean) }
  def can_post?(user)
    PostPolicy.new(user, @model.posts.new).create? && !@model.resolved?
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

  # The scene screen's footer page-action; see ScenePageAction, which owns the
  # rule and the data shape.
  sig do
    params(
      can_manage: T::Boolean,
      is_participant: T::Boolean,
      membership: T.nilable(GameMember)
    ).returns(T.nilable(ScenePageAction))
  end
  def page_action(can_manage:, is_participant:, membership:)
    ScenePageAction.for(
      scene: @model,
      viewer: ScenePageAction::Viewer.new(
        can_manage: can_manage, is_participant: is_participant, membership: membership
      )
    )
  end
end
