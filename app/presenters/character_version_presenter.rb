# typed: strict

# View model for one row of a character's version history. Wraps a
# CharacterVersion and exposes the editor's display name directly, so the
# version-history component no longer needs a separate `editor_names` lookup
# hash keyed by version id alongside the array of versions — that pairing was
# a join the presenter should have done.
class CharacterVersionPresenter < BasePresenter
  extend T::Sig

  sig { returns(Time) }
  def created_at
    @model.created_at
  end

  sig { returns(String) }
  def content
    @model.content.to_s
  end

  sig { returns(T::Boolean) }
  def content?
    @model.content.present?
  end

  sig { returns(String) }
  def formatted_created_at
    @model.created_at.strftime("%b %-d, %Y %-I:%M %p")
  end

  sig { returns(String) }
  def created_at_iso8601
    @model.created_at.iso8601
  end

  sig { returns(String) }
  def editor_name
    UserPresenter.new(@model.edited_by).display_name_or_email
  end
end
