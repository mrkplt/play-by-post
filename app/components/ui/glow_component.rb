# typed: strict

class Ui::GlowComponent < ApplicationComponent
  extend T::Sig

  sig { params(active: T::Boolean).void }
  def initialize(active: false)
    @active = active
  end

  sig { returns(T::Boolean) }
  def active?
    @active
  end
end
