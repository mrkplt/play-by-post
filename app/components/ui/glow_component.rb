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

  sig { returns(String) }
  def wrapper_class
    active? ? "ui-glow" : ""
  end

  sig { returns(T::Hash[Symbol, T.untyped]) }
  def wrapper_html_attributes
    attrs = { class: wrapper_class }
    attrs[:data] = { new_activity: true } if active?
    attrs
  end
end
