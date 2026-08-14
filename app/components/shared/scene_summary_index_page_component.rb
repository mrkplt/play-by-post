# typed: strict

class Shared::SceneSummaryIndexPageComponent < ApplicationComponent
  extend T::Sig

  sig { params(summaries: SceneSummaryCollectionPresenter).void }
  def initialize(summaries:)
    @summaries = T.let(summaries, SceneSummaryCollectionPresenter)
  end

  sig { returns(T::Boolean) }
  def summaries_empty?
    @summaries.empty?
  end

  sig { returns(T::Array[SceneSummaryPresenter]) }
  def entries
    @summaries.entries
  end

  sig { returns(String) }
  def pagy_nav
    @summaries.pagy_nav
  end
end
