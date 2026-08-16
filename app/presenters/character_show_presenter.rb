# typed: strict

# View model for CharactersController#show's extra chrome: the owning
# player's byline and the sheet's version history. Wraps the raw Character —
# split out purely to keep CharacterPresenter under the project's
# method-count ceiling, the same reason ScenePresenter has a sibling
# ScenePostsPresenter/SceneShowPresenter.
class CharacterShowPresenter < BasePresenter
  extend T::Sig

  sig { params(model: Character, options: T.untyped).void }
  def initialize(model, **options)
    super
  end

  # The sheet's owning player, for the show screen's "Player: …" byline.
  sig { returns(UserPresenter) }
  def owner
    UserPresenter.new(@model.user)
  end

  # This sheet's edit history, newest first, for the version-history component.
  sig { returns(T::Array[CharacterVersionPresenter]) }
  def versions
    @model.character_versions.order(created_at: :desc).includes(:edited_by)
      .map { |version| CharacterVersionPresenter.new(version) }
  end
end
