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

  # The character's portrait library as component-ready Item hashes.
  sig { returns(T::Array[Shared::ImageLibraryComponent::Item]) }
  def portrait_items
    portrait_library.items
  end

  # Whether the viewer may manage this character's portraits — the owning player
  # only (CharacterImagePolicy), threaded in from the controller.
  sig { returns(T::Boolean) }
  def can_manage_portraits?
    portrait_library.can_manage?
  end

  # Where the cropper posts a new portrait.
  sig { returns(String) }
  def portrait_upload_url
    portrait_library.upload_url
  end

  # Where the generator posts a prompt / the poll reloads (same singleton path,
  # verb differentiates).
  sig { returns(String) }
  def portrait_generation_url
    @options.fetch(:helpers).game_character_portrait_generation_path(@options.fetch(:game), @model)
  end

  private

  sig { returns(CharacterPortraitLibraryPresenter) }
  def portrait_library
    @portrait_library ||= T.let(
      CharacterPortraitLibraryPresenter.new(
        character: @model,
        game: @options.fetch(:game),
        can_manage: @options.fetch(:can_manage_portraits),
        helpers: @options.fetch(:helpers)
      ),
      T.nilable(CharacterPortraitLibraryPresenter)
    )
  end
end
