# typed: strict

# The button's visual configuration: which palette variant, which size step,
# and whether it renders disabled. Grouping these keeps
# Ui::ButtonComponent's own parameter list to this bundle plus the separate
# Link concern (see button_component/link.rb).
class Ui::ButtonComponent::Style < T::Struct
  extend T::Sig

  const :variant, Symbol, default: :primary
  const :size, Symbol, default: :md
  const :state, Symbol, default: :enabled

  sig { returns(T::Boolean) }
  def disabled?
    state == :disabled
  end
end
