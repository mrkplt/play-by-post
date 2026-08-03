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
end
