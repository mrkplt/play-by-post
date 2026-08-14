# typed: strict

# View model for the layout's flash: turns Rails' `notice`/`alert` keys into
# the ordered, display-ready toasts Ui::ToastComponent renders.
#
# The key→variant decision is display logic, which is why it lives here rather
# than in the component or the layout: the component decides what a success
# toast looks like, this decides that a `notice` *is* one. Unknown flash keys
# (`:timedout` from Devise, anything a gem sets) are dropped rather than
# rendered raw — the app only has a visual language for these two.
class FlashPresenter < BasePresenter
  extend T::Sig

  # Errors first: when a write half-succeeds and sets both, the problem is
  # the part the reader needs to see, and it is the one that will still be
  # on screen after the success toast fades.
  VARIANTS = T.let(
    {
      "alert" => :error,
      "notice" => :success
    }.freeze,
    T::Hash[String, Symbol]
  )

  sig { params(model: T.untyped, options: T.untyped).void }
  def initialize(model, **options)
    super
  end

  sig { returns(T::Array[Ui::ToastComponent::Toast]) }
  def toasts
    VARIANTS.filter_map do |key, variant|
      message = __getobj__[key]
      next if message.blank?

      { message: message.to_s, variant: variant }
    end
  end
end
