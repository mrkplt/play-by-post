# typed: strict

# The header's title and its two independent display flags — whether the
# text renders in the accent colour, and whether a GM crown precedes it.
# Grouping them here (rather than as three initialize parameters on
# Shared::HeaderComponent) keeps the header's own parameter list to the four
# structurally distinct slots: title, gear, breadcrumbs, secondary_nav.
class Shared::HeaderComponent::Title < T::Struct
  const :text, String
  const :accent, T::Boolean, default: false
  const :crown, T::Boolean, default: false
end
