# typed: strict

module Games
  # The GM-only setting switches; the flip and its wording live in
  # GameSettingToggle.
  class SettingsController < ApplicationController
    extend T::Sig

    after_action :verify_authorized

    sig { void }
    def sheets_hidden
      toggle(:sheets_hidden) { |target| game_path(target) }
    end

    sig { void }
    def images_disabled
      toggle(:images_disabled) { |target| edit_game_path(target) }
    end

    sig { void }
    def ai_summaries_enabled
      toggle(:ai_summaries_enabled) { |target| game_player_management_path(target) }
    end

    private

    sig { params(setting: Symbol, destination: T.proc.params(game: Game).returns(String)).void }
    def toggle(setting, &destination)
      target = game
      authorize target, :manage?

      redirect_to destination.call(target), notice: GameSettingToggle.new(target, setting).call
    end

    # A member route on games, so the game arrives as :id.
    sig { returns(Game) }
    def game
      Game.find(params[:id])
    end
  end
end
