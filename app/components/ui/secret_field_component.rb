# typed: strict

# Read-only field for a sensitive value (a token, a feed URL carrying a token).
# The value is masked by default; a toggle reveals it and a button copies the
# real value to the clipboard. Behaviour lives in the `secret-field` Stimulus
# controller.
class Ui::SecretFieldComponent < ApplicationComponent
  extend T::Sig

  INPUT_CLASSES = T.let(
    "flex-1 min-w-0 text-[11px] bg-canvas px-2 py-1 rounded border border-card-border " \
    "text-row-ink font-mono truncate",
    String
  )

  BUTTON_CLASSES = T.let(
    "text-[11px] font-bold text-accent bg-transparent border-0 cursor-pointer p-0 whitespace-nowrap",
    String
  )

  sig { params(value: String, label: String).void }
  def initialize(value:, label:)
    @value = value
    @label = label
  end

  sig { returns(String) }
  attr_reader :value

  sig { returns(String) }
  attr_reader :label
end
