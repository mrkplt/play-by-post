# typed: strict

# A read-only field holding a sensitive value (an API/feed token URL). The value
# is masked by default; a toggle reveals it and a button copies the real value to
# the clipboard. Presentational only — the `secret-field` Stimulus controller owns
# the reveal/copy behaviour; the component just renders the masked value, the real
# value (for copy), and the controls.
class Ui::SecretFieldComponent < ApplicationComponent
  extend T::Sig

  sig { params(value: String, label: String, revoke_path: T.nilable(String)).void }
  def initialize(value:, label:, revoke_path: nil)
    @value = value
    @label = label
    @revoke_path = revoke_path
  end

  sig { returns(String) }
  attr_reader :value

  sig { returns(String) }
  attr_reader :label

  sig { returns(T.nilable(String)) }
  attr_reader :revoke_path

  # The dotted placeholder shown until the field is revealed. Fixed length so the
  # real value's length isn't leaked by the mask width.
  sig { returns(String) }
  def masked_value
    "•" * 24
  end
end
