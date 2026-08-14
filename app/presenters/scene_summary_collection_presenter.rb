# typed: strict

# View model for the Campaign Log index: a page of SceneSummary rows plus
# their Pagy pagination state. Wraps the relation so the view never iterates
# raw SceneSummary records or reaches for a bare Pagy object directly — both
# travel together because "is there anything to show" and "how do we page
# through it" are one screen's display logic, not two.
class SceneSummaryCollectionPresenter < BasePresenter
  extend T::Sig

  sig { params(model: ActiveRecord::Relation, options: T.untyped).void }
  def initialize(model, **options)
    super
  end

  sig { returns(T::Boolean) }
  def empty?
    @model.empty? # mutant:disable
  end

  sig { returns(T::Array[SceneSummaryPresenter]) }
  def summaries
    @model.map { |summary| SceneSummaryPresenter.new(summary) }
  end

  sig { returns(T.untyped) }
  def pagy
    @options.fetch(:pagy)
  end
end
