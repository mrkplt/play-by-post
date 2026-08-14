# typed: strict

# View model for which characters are currently participating in a scene, on
# the standalone Edit Participants screen. Wraps the raw character-id list the
# controller queries so the view never holds a bare T::Array[Integer] — the
# checkbox list needs it as strings (matching CharacterPresenter#checkbox_value)
# for comparison, which is exactly the kind of formatting decision a presenter
# owns rather than the view calling .map(&:to_s) itself.
class SceneParticipantRosterPresenter < BasePresenter
  extend T::Sig

  sig { params(model: T::Array[Integer], options: T.untyped).void }
  def initialize(model, **options)
    super
  end

  sig { returns(T::Array[String]) }
  def selected_character_ids
    @model.map(&:to_s)
  end
end
