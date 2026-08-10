# typed: strict

# A generalized "label + one-or-more trailing controls" row for page-body
# placement (no card background/divider — see Ui::SettingsRowComponent for
# the card-list variant). Used on the scene screen for the participants/mute
# info row and the GM actions row. `label:` is optional (the GM actions row
# has no leading label, just a run of controls); trailing controls are
# supplied as block content, same pattern as Ui::SettingsRowComponent.
class Shared::ControlRowComponent < ApplicationComponent
  extend T::Sig

  sig { params(label: T.nilable(String)).void }
  def initialize(label: nil)
    @label = label
  end

  sig { returns(T::Boolean) }
  def label?
    @label.present?
  end

  sig { returns(String) }
  def label
    T.must(@label)
  end
end
