# typed: strict

# The shared Game name/description form, used by both New Game (games#new) and
# Edit Game (games#edit). Rails routes a new record to POST /games and a
# persisted one to PATCH /games/:id, so the same form_with drives create and
# update. Submit-side configuration (label, cancel target, optional note and
# confirm prompt) travels as one Submission (see
# game_form_component/submission.rb).
class Shared::GameFormComponent < ApplicationComponent
  extend T::Sig

  sig { params(game: GamePresenter, submission: Submission).void }
  def initialize(game:, submission:)
    @game = T.let(game, GamePresenter)
    @submission = T.let(submission, Submission)
  end

  sig { returns(GamePresenter) }
  attr_reader :game

  sig { returns(String) }
  def submit_label
    @submission.label
  end

  sig { returns(String) }
  def cancel_href
    @submission.cancel_href
  end

  sig { returns(T.nilable(String)) }
  def note
    @submission.note
  end

  sig { returns(T::Boolean) }
  def note?
    note.present?
  end

  sig { returns(T::Array[String]) }
  def error_messages
    game.error_messages
  end

  # The submit button's data hash — carries a Turbo/UJS confirmation prompt only
  # when the caller asked for one, keeping the template free of inline logic.
  sig { returns(T::Hash[Symbol, String]) }
  def submit_data
    confirm = @submission.confirm
    confirm ? { confirm: confirm } : {}
  end
end
