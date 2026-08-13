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

  # The scene screen's single footer page-action, if any: "Join Scene" for an
  # eligible non-participant on an open public scene, "Write Summary" for the
  # GM on a resolved scene with no summary yet, or nil (no footer action).
  #
  # Returns the button's label, route and HTTP method rather than a symbol the
  # template has to branch on: the two actions differ only in those three
  # values, so handing them back as data collapses the view's case/when into a
  # single conditional render. Adding a third footer action is a branch here,
  # not new markup there.
  #
  # `route` is the helper name, not a built URL — building one needs persisted
  # ids, which would drag this presenter (and every spec touching it) onto the
  # database for what is otherwise pure computation. The template resolves it
  # against the scene it already has.
  # `http_method`, not `method` — T::Struct refuses a prop that shadows
  # Kernel#method.
  class PageAction < T::Struct
    const :label, String
    const :route, Symbol
    const :http_method, T.nilable(Symbol)
  end

  sig do
    params(
      can_manage: T::Boolean,
      is_participant: T::Boolean,
      membership: T.nilable(GameMember)
    ).returns(T.nilable(PageAction))
  end
  def page_action(can_manage:, is_participant:, membership:)
    membership_active = membership.present? && membership.active?

    if !is_participant && !can_manage && !@model.private? && !@model.resolved? && membership_active
      PageAction.new(label: "Join Scene", route: :join_game_scene_participants_path, http_method: :post)
    elsif can_manage && @model.resolved? && @model.scene_summary.blank?
      PageAction.new(label: "Write Summary", route: :new_game_scene_scene_summary_path, http_method: nil)
    end
  end
end
