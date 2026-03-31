# typed: true

class BasePresenter < SimpleDelegator
  extend T::Sig
  extend T::Helpers
  abstract!

  sig { params(model: T.untyped).void }
  def initialize(model)
    super
    @model = T.let(model, T.untyped)
  end
end
