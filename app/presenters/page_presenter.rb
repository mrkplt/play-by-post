# typed: strict

# View model for a single game page, on the New/Edit Page forms and the Page
# show screen. Both the game-nav "can manage" flag and the page's own manage
# capability are asked of policies supplied at construction
# (options[:game_policy] / options[:page_policy]) rather than looked up in
# the view.
class PagePresenter < BasePresenter
  extend T::Sig

  sig { returns(T::Boolean) }
  def can_manage_game?
    @options.fetch(:game_policy).manage?
  end

  sig { returns(T::Boolean) }
  def can_manage?
    @options.fetch(:page_policy).manage?
  end

  sig { returns(T::Boolean) }
  def new_record? = @model.new_record?

  sig { returns(T.nilable(Integer)) }
  def id = @model.id

  sig { returns(T.nilable(String)) }
  def title = @model.title

  sig { returns(T::Boolean) }
  def body? = @model.body.present?

  sig { returns(String) }
  def body
    @model.body.to_s
  end

  sig { returns(T::Boolean) }
  def errors? = @model.errors.any?

  sig { returns(T::Array[String]) }
  def error_messages
    @model.errors.full_messages
  end

  # The Rails model instance this presenter wraps — for `form_with model:`
  # and route helpers, which need the real ActiveRecord object.
  sig { returns(Page) }
  def to_model
    @model
  end
end
