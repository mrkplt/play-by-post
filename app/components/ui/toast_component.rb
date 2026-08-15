# typed: strict

# Transient confirmations overlaid on the current screen — the app's only
# flash surface, rendered once from the layout.
#
# Takes already-derived toasts rather than the raw `notice`/`alert` locals:
# deciding that a notice is a success and an alert is an error is display
# logic, so it belongs to a presenter (FlashPresenter), and this component
# only decides markup. The `Toast` shape is a named interface for that data,
# not a class — the same pattern as `Badge` on Shared::StatusBadgeRowComponent.
#
# Success toasts dismiss themselves (the toast Stimulus controller holds them
# solid, then fades); errors persist with a close button, because an error
# missed is worse than a banner left standing.
class Ui::ToastComponent < ApplicationComponent
  extend T::Sig

  Toast = T.type_alias { { message: String, variant: Symbol } }

  VARIANT_CLASSES = T.let(
    {
      success: "toast toast--success",
      error: "toast toast--error"
    }.freeze,
    T::Hash[Symbol, String]
  )

  # Only success toasts are timed out; anything else waits to be dismissed.
  SELF_DISMISSING = T.let([ :success ].freeze, T::Array[Symbol])

  sig { params(toasts: T::Array[Toast]).void }
  def initialize(toasts: [])
    @toasts = toasts
  end

  sig { returns(T::Array[Toast]) }
  attr_reader :toasts

  sig { params(toast: Toast).returns(String) }
  def classes_for(toast)
    VARIANT_CLASSES.fetch(toast[:variant])
  end

  # Each toast is its own Stimulus controller scope so several can fade on
  # independent timers. Every toast gets the controller — an error toast needs
  # it for its dismiss button even though it starts no timer — and the
  # auto-dismiss value is what decides whether that timer runs.
  sig { params(toast: Toast).returns(T::Hash[Symbol, T.untyped]) }
  def data_for(toast)
    { data: { controller: "toast", toast_auto_dismiss_value: self_dismissing?(toast) } }
  end

  sig { params(toast: Toast).returns(T::Boolean) }
  def self_dismissing?(toast)
    SELF_DISMISSING.include?(toast[:variant])
  end

  # Errors are the ones that stay, so they are the ones that need a way out.
  sig { params(toast: Toast).returns(T::Boolean) }
  def dismissible?(toast)
    !self_dismissing?(toast)
  end
end
