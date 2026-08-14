# typed: strict

# View model for the standalone Edit Participants screen: which players may
# be added to the scene, each paired with their active characters, plus
# which character ids are currently selected.
#
# Shared::ParticipantCheckboxListComponent's own contract (an array of
# [UserPresenter, T::Array[Character]] tuples) is unchanged here — this
# presenter exists to give the *controller's* ivar a presenter-classified
# type, not to change what the component receives. Rewriting that shared
# contract (also used by Shared::SceneFormComponent, built from
# ScenesController) is out of this screen's scope.
class SceneParticipantRosterPresenter < BasePresenter
  extend T::Sig

  sig { params(model: T::Array[Shared::ParticipantCheckboxListComponent::PlayerRow], options: T.untyped).void }
  def initialize(model, **options)
    super
  end

  sig { returns(T::Array[Shared::ParticipantCheckboxListComponent::PlayerRow]) }
  def rows
    @model
  end

  sig { returns(T::Array[String]) }
  def selected_character_ids
    @options.fetch(:selected_character_ids)
  end
end
