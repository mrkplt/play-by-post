# typed: strict

class BasePresenter < SimpleDelegator
  extend T::Sig
  extend T::Helpers
  abstract!

  # (model, options) — see Fizzy #95. Collaborators a view would otherwise
  # reach for (a policy, a parent record, url_helpers) are supplied here at
  # construction; subclasses read them from @options rather than taking
  # per-call parameters.
  sig { params(model: T.untyped, options: T.untyped).void }
  def initialize(model, **options)
    super(model)
    @model = model
    @options = T.let(options, T::Hash[Symbol, T.untyped])
  end
end
