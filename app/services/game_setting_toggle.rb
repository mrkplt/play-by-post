# typed: strict
# frozen_string_literal: true

# Flips one of a game's GM-facing boolean settings and reports what to say
# about it. The three settings differ only in the flag and the wording, so the
# flip lives here once and the controller keeps only its own concerns —
# authorization and where each toggle returns to.
class GameSettingToggle
  extend T::Sig

  # Copy for each setting, keyed on the value it lands on.
  NOTICES = T.let(
    {
      sheets_hidden: { true => "Character sheets are now hidden.", false => "Character sheets are now visible." },
      ai_summaries_enabled: { true => "AI scene summaries enabled.", false => "AI scene summaries disabled." },
      player_contributions_enabled: {
        true => "Players can now add pages, links, and files.",
        false => "Player contributions are now off."
      }
    }.freeze,
    T::Hash[Symbol, T::Hash[T::Boolean, String]]
  )

  sig { params(game: Game, setting: Symbol).void }
  def initialize(game, setting)
    @game = game
    @setting = setting
  end

  # Flips the flag and returns the notice for its new value.
  sig { returns(String) }
  def call
    flipped = !@game.public_send(:"#{@setting}?")
    @game.update!(@setting => flipped)

    NOTICES.fetch(@setting).fetch(flipped)
  end
end
