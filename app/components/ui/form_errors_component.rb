# typed: strict

# The validation-error block that sits at the top of a form, above the fields.
# Renders nothing when there are no messages, so callers hand it the messages
# unconditionally rather than wrapping the render in their own `if errors?`.
#
# This is the error tint specifically. Other blocks in the app share the
# `tint-blue` background for non-error purposes (draft recovery notices, scene
# resolution text) — matching colours is not matching meaning, and those are
# deliberately not routed through here.
class Ui::FormErrorsComponent < ApplicationComponent
  extend T::Sig

  CLASSES = T.let(
    "bg-tint-blue-bg border border-tint-blue-border rounded-card p-3 text-sm text-danger",
    String
  )

  sig { params(messages: T::Array[String]).void }
  def initialize(messages:)
    @messages = messages
  end

  sig { returns(T::Array[String]) }
  attr_reader :messages

  sig { returns(T::Boolean) }
  def render?
    messages.any?
  end
end
