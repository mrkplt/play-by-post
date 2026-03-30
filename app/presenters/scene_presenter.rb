# typed: true

class ScenePresenter < BasePresenter
  extend T::Sig

  sig { returns(String) }
  def status_badge_css_class
    resolved? ? "badge badge--gray" : "badge badge--green"
  end

  sig { returns(String) }
  def status_label
    resolved? ? "Resolved" : "Active"
  end

  sig { returns(String) }
  def participant_names
    scene_participants
      .includes(:character, :user)
      .reject { |sp| sp.character_id.nil? }
      .map(&:display_name)
      .join(", ")
  end

  sig { returns(String) }
  def formatted_created_at
    created_at.strftime("%b %-d, %Y %l:%M%P")
  end
end
