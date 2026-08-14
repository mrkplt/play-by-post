# typed: strict

# The "Image attachments" settings row on the Edit Game screen: a text-link
# control that flips whether players may attach images to posts. Owns the
# full row (label, sub-label, toggle link) rather than being a bare button —
# same pattern as Shared::AiSummariesToggleComponent.
class Shared::ImagesToggleComponent < ApplicationComponent
  extend T::Sig

  sig { params(game: GamePresenter).void }
  def initialize(game:)
    @game = T.let(game, GamePresenter)
  end

  sig { returns(T::Boolean) }
  def disabled?
    @game.images_disabled?
  end

  sig { returns(String) }
  def toggle_label
    disabled? ? "Enable" : "Disable"
  end

  sig { returns(String) }
  # mutant:disable
  def toggle_path
    T.unsafe(helpers).toggle_images_disabled_game_path(@game)
  end
end
