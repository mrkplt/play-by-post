# typed: strict
# frozen_string_literal: true

# Builds the Turbo Streams the portrait generation control answers with, so the
# controller stays thin (mirrors the BYOK controller's streams object). It owns:
#
#   - #control: replace just the generation control (its pending/failed/idle
#     state) — used by #create and while the poll is still pending.
#   - #settled: the poll's settle response — the control (idle again), the
#     refreshed portrait library, and a completion/failure toast.
#
# State (pending + the optional failure reason) is grouped into one value object
# so the stream methods don't pass the pair around.
class CharacterPortraitStreamsPresenter
  extend T::Sig

  CONTROL_TARGET = Shared::PortraitGeneratorComponent::TARGET_ID
  LIBRARY_TARGET = "image_library_character_image"
  TOAST_TARGET = "toast_layer"

  # The control's render state.
  class State < T::Struct
    const :pending, T::Boolean, default: false
    const :failure_reason, T.nilable(String), default: nil
  end

  sig do
    params(
      character: Character, game: Game, generate_url: String, helpers: T.untyped
    ).void
  end
  def initialize(character:, game:, generate_url:, helpers:)
    @character = character
    @game = game
    @generate_url = generate_url
    @helpers = helpers
  end

  # Replace only the control — used by #create and each still-pending poll.
  sig { params(state: State).returns(T.untyped) }
  def control(state)
    @helpers.turbo_stream.replace(CONTROL_TARGET, generator_component(state))
  end

  # The poll's settle response: idle control + refreshed library + a toast.
  sig { params(failure_reason: T.nilable(String)).returns(T::Array[T.untyped]) }
  def settled(failure_reason:)
    turbo = @helpers.turbo_stream
    [
      control(State.new(failure_reason: failure_reason)),
      turbo.replace(LIBRARY_TARGET, library_component),
      turbo.replace(TOAST_TARGET, toast_component(failure_reason))
    ]
  end

  private

  sig { params(state: State).returns(Shared::PortraitGeneratorComponent) }
  def generator_component(state)
    Shared::PortraitGeneratorComponent.new(
      generate_url: @generate_url, poll_url: @generate_url,
      pending: state.pending, failure_reason: state.failure_reason
    )
  end

  sig { returns(Shared::ImageLibraryComponent) }
  def library_component
    presenter = CharacterPortraitLibraryPresenter.new(
      character: @character, game: @game, can_manage: true, helpers: @helpers
    )
    Shared::ImageLibraryComponent.new(
      title: "Portraits", images: presenter.items, can_manage: true, empty_text: "No portraits yet."
    )
  end

  sig { params(failure_reason: T.nilable(String)).returns(Ui::ToastComponent) }
  def toast_component(failure_reason)
    toast = failure_reason ? { message: failure_reason, variant: :error } : { message: "Portrait generated.", variant: :success }
    Ui::ToastComponent.new(toasts: [ toast ])
  end
end
