# typed: strict

# View model for a game page (detail, form, and list-row screens). The GM-only
# manage capability is asked of a policy supplied at construction
# (options[:policy]) rather than looked up in the view, so a capability rename
# is chased through one construction point instead of every page template.
class PagePresenter < BasePresenter
  extend T::Sig

  sig { returns(T::Boolean) }
  def can_manage?
    @options.fetch(:policy).manage?
  end

  sig { returns(Game) }
  def game
    @model.game
  end

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

  sig { returns(T::Boolean) }
  def new_record? = @model.new_record?

  sig { returns(T.nilable(String)) }
  def slug = @model.slug

  sig { returns(T.nilable(Integer)) }
  def id = @model.id

  sig { returns(T::Boolean) }
  def errors?
    @model.errors.any?
  end

  sig { returns(T::Array[String]) }
  def error_messages
    @model.errors.full_messages
  end
end
