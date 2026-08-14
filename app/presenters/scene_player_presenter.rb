# typed: strict

# View model for one player row in the scene-participant checkbox list
# (Shared::ParticipantCheckboxListComponent): the player's display name paired
# with their active characters. Replaces the PlayerRow tuple
# (`[UserPresenter, T::Array[Character]]`) that used to carry a raw model
# array straight into the component — the tuple hid the Character models from
# the view-layering gate without actually keeping them out of the component.
class ScenePlayerPresenter < BasePresenter
  extend T::Sig

  sig { params(model: User, options: T.untyped).void }
  def initialize(model, **options)
    super
  end

  sig { returns(String) }
  def display_name_or_email
    @model.display_name || @model.email.split("@").first
  end

  sig { returns(T::Array[CharacterPresenter]) }
  def characters
    @options.fetch(:characters).map { |character| CharacterPresenter.new(character) }
  end

  sig { returns(T::Boolean) }
  def characters?
    characters.any?
  end
end
