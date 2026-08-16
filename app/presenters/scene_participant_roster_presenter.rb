# typed: strict

# View model for the standalone Edit Participants screen's checkbox list: which
# characters are currently participating in a scene, plus every eligible
# player/character pairing to check them against. Wraps the raw selected-id
# list the controller queries so the view never holds a bare T::Array[Integer]
# — the checkbox list needs it as strings (matching
# CharacterPresenter#checkbox_value) for comparison, which is exactly the kind
# of formatting decision a presenter owns rather than the view calling
# .map(&:to_s) itself. `players_with_characters` (options[:players_with_characters])
# is folded in here rather than a second controller ivar, since the two are
# always constructed and read together.
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

  sig { returns(T::Array[ScenePlayerPresenter]) }
  def players_with_characters
    @options.fetch(:players_with_characters)
  end
end
