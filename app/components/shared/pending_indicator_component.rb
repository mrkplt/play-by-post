# typed: strict

# The waiting row every async-pending surface shares: a small spinner beside a
# message. Shared::AsyncPendingComponent renders it inside its cable-subscribed
# frame, and Ui::ByokKeyFormComponent inside its polling frame — the layout is
# spelled once here. Wrapper `data` attributes are parameterized so a caller
# can wire a Stimulus controller (e.g. frame-poll) onto the row without
# respelling it.
class Shared::PendingIndicatorComponent < ApplicationComponent
  extend T::Sig

  sig { params(message: String, data: T::Hash[Symbol, T.untyped]).void }
  def initialize(message:, data: {})
    @message = message
    @data = data
  end

  sig { returns(String) }
  attr_reader :message

  sig { returns(T::Hash[Symbol, T.untyped]) }
  attr_reader :data
end
