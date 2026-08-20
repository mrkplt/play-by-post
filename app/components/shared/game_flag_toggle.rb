# typed: strict

# The plumbing every "flip a boolean game flag" control repeats: given the flag's
# current state and the label for each direction, pick the action label. The two
# adopters (SheetsToggleComponent, AiSummariesToggleComponent) each read a
# different flag off the game, link to a different route, and present themselves
# completely differently (a settings row vs a labelled card) — so only the
# label-flip logic is shared here, not the presentation or the path.
#
# Including components implement `on?`, `on_label` and `off_label` and get
# `toggle_label`. `toggle_path` stays on each component because the routes differ.
#
# Deliberately a plain module rather than an ActiveSupport::Concern — this
# project does not use concerns, and `bin/check-concerns` enforces that.
module Shared::GameFlagToggle
  extend T::Sig
  extend T::Helpers

  abstract!

  # Whether the flag is currently on.
  sig { abstract.returns(T::Boolean) }
  def on?; end

  # The action label shown when the flag is on (the button turns it off), and
  # when it is off (the button turns it on).
  sig { abstract.returns(String) }
  def on_label; end

  sig { abstract.returns(String) }
  def off_label; end

  # The button label: when the flag is on, the button turns it off, and vice
  # versa.
  sig { returns(String) }
  def toggle_label
    on? ? on_label : off_label
  end
end
