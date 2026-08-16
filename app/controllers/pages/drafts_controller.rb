# typed: strict

module Pages
  # A page's in-progress draft. The editor autosaves the `draft` flag on the
  # page's own row (a page is one row — unlike a post, there is no separate draft
  # record), and publishing promotes it to visible. Both are GM-only. The
  # save/publish machinery is shared via Draftable::Controller; this controller
  # supplies only the page-specific lookup, params, and redirect.
  class DraftsController < ApplicationController
    extend T::Sig
    include Draftable::Controller

    before_action :require_game_access!
    after_action :verify_authorized

    sig { void }
    def save
      draftable_save
    end

    sig { void }
    def publish
      draftable_publish
    end

    private

    sig { override.returns(Page) }
    def draftable_record
      page
    end

    sig { override.returns(ActionController::Parameters) }
    def draftable_params
      params.require(:page).permit(:title, :body)
    end

    sig { override.params(record: T.untyped).returns(String) }
    def draftable_published_path(record)
      game_page_path(game, record)
    end

    sig { override.returns(String) }
    def draftable_published_notice
      "Page published."
    end

    sig { returns(Game) }
    def game
      Game.find_by!(slug: params[:game_id])
    end

    sig { returns(Page) }
    def page
      game.pages.find_by!(slug: params[:slug])
    end

    sig { void }
    def require_game_access!
      redirect_to root_path, alert: "You do not have access to this game." unless policy(game).view?
    end
  end
end
