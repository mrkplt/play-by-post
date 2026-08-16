# typed: strict

# Everything about the New Scene / Quick Scene form except its two domain
# subjects (the game and the scene being created): whether this is the quick
# or full form, where Cancel goes, and — for the full form — the
# participant/parent-scene picker state (which players and parent scenes are
# offered, and which of each arrived pre-selected, whether from a resubmit or
# from characters/parent already attached to the scene being edited). Quick
# scenes render none of the picker fields. Travels as one Selection rather
# than six initialize parameters on Shared::SceneFormComponent.
class Shared::SceneFormComponent::Selection < T::Struct
  const :quick, T::Boolean
  const :back_href, String
  const :players_with_characters, T::Array[ScenePlayerPresenter], default: []
  const :parent_options, T::Array[[ String, Integer ]], default: []
  const :selected_character_ids, T::Array[String], default: []
  const :selected_parent_scene_id, T.nilable(String), default: nil
end
