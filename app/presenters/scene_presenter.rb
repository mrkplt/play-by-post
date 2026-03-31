# typed: true

class ScenePresenter < BasePresenter
  extend T::Sig

  sig { returns(String) }
  def status_label
    @model.resolved? ? "Resolved" : "Active"
  end

  sig { returns(String) }
  def participant_names
    @model.scene_participants
      .includes(:character, :user)
      .reject { |sp| sp.character_id.nil? }
      .map(&:display_name)
      .join(", ")
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
end
