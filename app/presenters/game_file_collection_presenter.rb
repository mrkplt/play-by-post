# typed: strict

# View model for a game's file library: the Files tab's "is there anything to
# show" question, plus the models Shared::GalleryComponent still needs while
# it (a component outside this bundle) has not yet been converted to take
# presenters directly.
class GameFileCollectionPresenter < BasePresenter
  extend T::Sig

  sig { params(model: ActiveRecord::Relation, options: T.untyped).void }
  def initialize(model, **options)
    super
  end

  sig { returns(T::Boolean) }
  def empty?
    @model.empty? # mutant:disable
  end

  sig { returns(T::Array[GameFile]) }
  def models
    @model.to_a
  end
end
