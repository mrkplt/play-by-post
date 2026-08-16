# typed: strict

# View model for one row of a page's version history. Wraps a PageVersion and
# exposes the editor's display name directly, mirroring
# CharacterVersionPresenter.
class PageVersionPresenter < BasePresenter
  extend T::Sig

  sig { returns(String) }
  def title
    @model.title.to_s
  end

  sig { returns(String) }
  def body
    @model.body.to_s
  end

  sig { returns(T::Boolean) }
  def body?
    @model.body.present?
  end

  sig { returns(String) }
  def formatted_created_at
    @model.created_at.strftime("%b %-d, %Y %-I:%M %p")
  end

  # ISO 8601, for the <time datetime="..."> attribute the version-history row
  # renders alongside #formatted_created_at's human-readable text.
  sig { returns(String) }
  def created_at_timestamp
    @model.created_at.iso8601
  end

  sig { returns(String) }
  def editor_name
    UserPresenter.new(@model.edited_by).display_name_or_email
  end
end
