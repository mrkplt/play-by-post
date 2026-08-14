# typed: strict

# The shared Game name/description form, used by both New Game (games#new) and
# Edit Game (games#edit). Rails routes a new record to POST /games and a
# persisted one to PATCH /games/:id, so the same form_with drives create and
# update. An optional note (the "you become the GM" line on creation) and an
# optional submit confirmation are supplied by the caller.
class Shared::GameFormComponent < ApplicationComponent
  extend T::Sig

  sig do
    params(
      game: GamePresenter,
      submit_label: String,
      cancel_href: String,
      note: T.nilable(String),
      confirm: T.nilable(String)
    ).void
  end
  def initialize(game:, submit_label:, cancel_href:, note: nil, confirm: nil)
    @game = T.let(game, GamePresenter)
    @submit_label = T.let(submit_label, String)
    @cancel_href = T.let(cancel_href, String)
    @note = T.let(note, T.nilable(String))
    @confirm = T.let(confirm, T.nilable(String))
  end

  sig { returns(GamePresenter) }
  attr_reader :game

  sig { returns(String) }
  attr_reader :submit_label

  sig { returns(String) }
  attr_reader :cancel_href

  sig { returns(T.nilable(String)) }
  attr_reader :note

  sig { returns(T::Boolean) }
  def note?
    @note.present?
  end

  sig { returns(T::Boolean) }
  def errors?
    @game.errors?
  end

  sig { returns(T::Array[String]) }
  def error_messages
    @game.error_messages
  end

  # The submit button's data hash — carries a Turbo/UJS confirmation prompt only
  # when the caller asked for one, keeping the template free of inline logic.
  sig { returns(T::Hash[Symbol, String]) }
  def submit_data
    @confirm ? { confirm: @confirm } : {}
  end
end
