# typed: strict

# The GM scene-actions block on the scene screen: a run of navigation actions
# (Quick Scene, New Scene, Edit Participants) followed by "End Scene", which
# reveals the resolve form. The `resolve-toggle` Stimulus controller toggles the
# form's visibility; the End Scene button targets it by Stimulus action.
#
# Owns the whole GM-actions structure — the control row, the four buttons, and
# the hidden resolve form — and takes the four presentation-ready paths, never a
# raw Scene.
class Shared::ResolveToggleComponent < ApplicationComponent
  extend T::Sig

  sig do
    params(
      quick_scene_path: String,
      new_scene_path: String,
      edit_participants_path: String,
      resolve_path: String
    ).void
  end
  def initialize(quick_scene_path:, new_scene_path:, edit_participants_path:, resolve_path:)
    @quick_scene_path = quick_scene_path
    @new_scene_path = new_scene_path
    @edit_participants_path = edit_participants_path
    @resolve_path = resolve_path
  end

  sig { returns(String) }
  attr_reader :quick_scene_path

  sig { returns(String) }
  attr_reader :new_scene_path

  sig { returns(String) }
  attr_reader :edit_participants_path

  sig { returns(String) }
  attr_reader :resolve_path
end
