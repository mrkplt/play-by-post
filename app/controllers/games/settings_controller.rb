# typed: strict

module Games
  # The GM-only setting switches; the flip and its wording live in
  # GameSettingToggle.
  class SettingsController < ApplicationController
    extend T::Sig
    include InPlaceRender

    after_action :verify_authorized

    sig { void }
    def sheets_hidden
      toggle(:sheets_hidden) { |game_presenter| Shared::SheetsToggleComponent.new(game: game_presenter) }
    end

    sig { void }
    def ai_summaries_enabled
      toggle(:ai_summaries_enabled) do |game_presenter|
        Shared::AiSummariesToggleComponent.new(game: game_presenter, presentation: ai_summaries_presentation)
      end
    end

    sig { void }
    def player_contributions_enabled
      toggle(:player_contributions_enabled) do |game_presenter|
        Shared::PlayerContributionsToggleComponent.new(game: game_presenter)
      end
    end

    private

    # Which presentation of the AI-summaries toggle to render back: the
    # button that triggered the flip carries its own screen's presentation
    # (see Shared::AiSummariesToggleComponent#toggle_path), defaulting to the
    # Edit Game card when absent so an un-parameterized request still works.
    sig { returns(Symbol) }
    def ai_summaries_presentation
      params[:presentation] == "row" ? :row : :card
    end

    # Flip the flag and swap just the toggle control in place (by its wrapper id)
    # plus a toast — a setting switch should not full-reload its whole screen.
    # flash.now, not flash: nothing redirects. The block builds the control for
    # the flipped state from a fresh GamePresenter.
    sig { params(setting: Symbol, control: T.proc.params(game: GamePresenter).returns(Shared::GameFlagToggle)).void }
    def toggle(setting, &control)
      target = game
      authorize target, :manage?

      flash.now[:notice] = GameSettingToggle.new(target, setting).call
      component = control.call(GamePresenter.new(target.reload, policy: policy(target)))
      render turbo_stream: [ turbo_stream.replace(component.wrapper_id, component), toast_stream ]
    end

    # A member route on games, so the game arrives as :id.
    sig { returns(Game) }
    def game
      Game.find_by!(slug: params[:id])
    end
  end
end
