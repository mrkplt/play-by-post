# typed: strict

# The AI-portrait generation control on the character screen, for the owning
# player (CharacterImagePolicy#manage?). Mirrors the BYOK keypair flow: #create
# enqueues the async job and renders the control's pending state; the pending
# spinner's frame-poll GET #show reloads the control until the skeleton is
# completed (the library shows the new portrait) or failed (the reason shows,
# and the dead skeleton is cleaned up).
#
# The whole thing happens in place inside the shared portrait frame — no action
# redirects.
class CharacterPortraitGenerationsController < ApplicationController
  extend T::Sig
  include RequestMemo

  before_action :require_game_access!
  after_action :verify_authorized

  # Enqueue a generation: create the pending skeleton, hand its id to the worker,
  # and render the control in its pending state. A prompt is required.
  sig { void }
  def create
    authorize character_image_scope.new, :manage?
    prompt = portrait_prompt
    return render(turbo_stream: streams.control(blank_prompt_state), layout: false) if prompt.blank?

    enqueue_generation(prompt)
    render turbo_stream: streams.control(pending_state), layout: false
  end

  # Poll target: return a Turbo Stream the portrait-poll Stimulus controller
  # applies. While a skeleton is still pending it replaces the control with the
  # spinner again (the controller reconnects and keeps polling). Once settled it
  # replaces the control with the form AND refreshes the library (so a finished
  # portrait appears), dropping a completion/failure toast.
  sig { void }
  def show
    authorize character_image_scope.new, :manage?
    reason = consume_failure_reason
    return render(turbo_stream: streams.control(pending_state), layout: false) if character_image_scope.pending.exists?

    render turbo_stream: streams.settled(failure_reason: reason), layout: false
  end

  private

  # Create the pending skeleton and hand its id to the worker.
  sig { params(prompt: String).void }
  def enqueue_generation(prompt)
    image = character_image_scope.create!
    CharacterPortraitJob.perform_later(image.id, current_user.id, prompt)
  end

  sig { returns(CharacterPortraitStreamsPresenter) }
  def streams
    CharacterPortraitStreamsPresenter.new(
      character: character, game: game, generate_url: generate_url, helpers: helpers
    )
  end

  sig { returns(CharacterPortraitStreamsPresenter::State) }
  def pending_state
    CharacterPortraitStreamsPresenter::State.new(pending: true)
  end

  sig { returns(CharacterPortraitStreamsPresenter::State) }
  def blank_prompt_state
    CharacterPortraitStreamsPresenter::State.new(failure_reason: "Please describe your character.")
  end

  # The newest failed skeleton's reason, if any — read once, then the dead
  # skeleton is deleted so the failure is shown exactly once and no dead rows
  # linger.
  sig { returns(T.nilable(String)) }
  def consume_failure_reason
    character_image_scope.failed.order(created_at: :desc).first&.consume_failure_reason!
  end

  sig { returns(T.nilable(String)) }
  def portrait_prompt
    params.dig(:portrait, :prompt)&.to_s&.strip
  end

  sig { returns(T.untyped) }
  def character_image_scope
    character.character_images
  end

  sig { returns(String) }
  def generate_url
    helpers.game_character_portrait_generation_path(game, character)
  end

  sig { returns(Game) }
  def game
    memo(:game) { Game.find_by!(slug: params[:game_id]) }
  end

  sig { returns(Character) }
  def character
    memo(:character) { game.characters.find(params[:character_id]) }
  end

  sig { void }
  def require_game_access!
    redirect_to root_path, alert: "You do not have access to this game." unless policy(game).view?
  end
end
