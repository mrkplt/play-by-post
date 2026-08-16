# typed: strict

class Ui::GlowComponent < ApplicationComponent
  extend T::Sig

  STATES = T.let(%i[glowing idle].freeze, T::Array[Symbol])

  sig { params(state: Symbol).void }
  def initialize(state: :idle)
    raise ArgumentError, "Unknown state: #{state}" unless STATES.include?(state)

    @state = state
  end

  sig { returns(T::Boolean) }
  def active?
    @state == :glowing
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
