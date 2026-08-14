# typed: strict

# The GM's "End Scene" resolve form, revealed by the End Scene button on the
# scene screen. The outcome is a markdown field: a formatting toolbar above the
# textarea and a live rendered preview below, matching every other prose field.
# Kept hidden until toggled; the toggle button targets this component's
# `resolve-form` id.
class Shared::SceneResolveFormComponent < ApplicationComponent
  extend T::Sig

  sig { params(resolve_path: String).void }
  def initialize(resolve_path:)
    @resolve_path = T.let(resolve_path, String)
  end

  sig { returns(String) }
  attr_reader :resolve_path
end
