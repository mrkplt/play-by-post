# typed: strict

# A row of status badges (Ui::BadgeComponent), fed a pre-computed array of
# label/variant pairs — never a raw model. Callers (presenters) decide which
# symbolic Ui::BadgeComponent variant applies; this component only lays the
# badges out. Renders nothing when the array is empty.
class Shared::StatusBadgeRowComponent < ApplicationComponent
  extend T::Sig

  Badge = T.type_alias { { label: String, variant: Symbol } }

  sig { params(badges: T::Array[Badge]).void }
  def initialize(badges:)
    @badges = T.let(badges, T::Array[Badge])
  end

  sig { returns(T::Array[Badge]) }
  attr_reader :badges

  sig { returns(T::Boolean) }
  def any?
    @badges.any?
  end
end
