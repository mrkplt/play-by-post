# typed: strict
# frozen_string_literal: true

module Ai
  # Composes the full prompt string for an AI character-portrait generation,
  # from three parts in order:
  #
  #   1. The fixed safety preamble (Ai::PortraitSafetyPrompt) — always first,
  #      always present, including its injection-resistance framing.
  #   2. The GM-designated environment/setting page body, when the game has one
  #      (Game#environment_prompt), else omitted.
  #   3. The player's own prompt.
  #
  # The two source parts are exposed separately (game_part / player_part) so the
  # refusal logger can record each alongside the full composed string when a
  # generation is refused by moderation.
  #
  # Pure: it reads a Game and a player-supplied string and returns text. No
  # persistence, no API call.
  class PortraitPrompt
    extend T::Sig

    sig { params(game: Game, player_prompt: String).void }
    def initialize(game:, player_prompt:)
      @game = game
      @player_prompt = player_prompt
    end

    # The GM environment/setting portion, or nil when no environment page is
    # designated (or its body is blank).
    sig { returns(T.nilable(String)) }
    def game_part
      @game.environment_prompt&.strip&.presence
    end

    # The player's own prompt, stripped.
    sig { returns(String) }
    def player_part
      @player_prompt.strip
    end

    # The full composed prompt: safety preamble, then the environment part (when
    # present), then the player part — separated by blank lines.
    sig { returns(String) }
    def to_s
      [ PortraitSafetyPrompt.text, game_part, player_part ].compact.join("\n\n")
    end
  end
end
