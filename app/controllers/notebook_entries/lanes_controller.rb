# typed: strict

module NotebookEntries
  # Moving an entry between notebook lanes, and promoting one out of the
  # notebook into a full game Page. Both are GM-only, authorized by
  # NotebookEntryPolicy#manage?, and both mutate the entry rather than editing
  # its text — which is NotebookEntriesController's job.
  class LanesController < ApplicationController
    extend T::Sig

    after_action :verify_authorized

    helper_method :game_presenter, :game_routes

    sig { void }
    def move
      entry = authorized_entry
      lane_move = NotebookLaneMove.new(params)
      entry.update!(lane_move.attributes)

      respond_to_move(entry, lane_move)
    end

    sig { void }
    def promote
      page = NotebookEntryPromotion.new(authorized_entry).call

      redirect_to game_page_path(game, page), notice: "Promoted to a page."
    end

    private

    # Branches on an explicit form field, not request format: Turbo advertises
    # turbo-stream for every unsafe request, so format.html would be dead code.
    sig { params(entry: NotebookEntry, lane_move: NotebookLaneMove).void }
    def respond_to_move(entry, lane_move)
      if lane_move.standalone?
        redirect_to edit_game_notebook_entry_path(game, entry), notice: "Entry moved."
      else
        @entry_presenter = T.let(NotebookEntryPresenter.new(entry), T.nilable(NotebookEntryPresenter))
        render :move, formats: :turbo_stream
      end
    end

    sig { returns(NotebookEntry) }
    def authorized_entry
      game.notebook_entries.find_by!(slug: params[:slug]).tap { |entry| authorize entry, :manage? }
    end

    sig { returns(Game) }
    def game
      Game.find(params[:game_id])
    end

    sig { returns(GamePresenter) }
    def game_presenter
      @game_presenter ||= T.let(
        GamePresenter.new(game, policy: policy(game), urls: self), T.nilable(GamePresenter)
      )
    end

    sig { returns(GameRoutesPresenter) }
    def game_routes = GameRoutesPresenter.new(game_presenter, urls: self)
  end
end
