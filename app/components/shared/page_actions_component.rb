# typed: strict

# The pinned footer action bar: a page's primary action (Save / Create /
# Update / Post) and, on forms, a Cancel. Rendered in
# Shared::MobileFrameComponent's `footer` slot so every screen keeps its
# action buttons in the same place — the body holds content only.
#
# `primary` and `cancel` are block-content slots (each expected to render a
# Ui::ButtonComponent) rather than a fixed label/url API, so callers keep
# full control of method/confirm/turbo behavior via Ui::ButtonComponent
# itself; PageActions only owns the layout.
class Shared::PageActionsComponent < ApplicationComponent
  extend T::Sig

  renders_one :primary
  renders_one :cancel
end
