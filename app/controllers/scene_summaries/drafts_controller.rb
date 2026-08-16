# typed: strict

module SceneSummaries
  # A scene summary's in-progress draft. The editor autosaves the `draft` flag
  # on the summary's own row — its scene_id is uniquely indexed, so a summary
  # cannot hold a separate draft row beside a published one — and publishing
  # promotes it into the members log and RSS feed. Both are GM-only. The
  # save/publish machinery is shared via Draftable::Controller; this controller
  # supplies only the summary-specific lookup, params, and redirect.
  class DraftsController < ApplicationController
    extend T::Sig
    include Draftable::Controller
    include SceneSummaryScoped

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

    sig { override.returns(SceneSummary) }
    def draftable_record
      T.must(summary)
    end

    sig { override.returns(ActionController::Parameters) }
    def draftable_params
      params.require(:scene_summary).permit(:body)
    end

    sig { override.params(_record: T.untyped).returns(String) }
    def draftable_published_path(_record)
      game_scene_path(game, scene)
    end

    sig { override.returns(String) }
    def draftable_published_notice
      "Summary published."
    end

    sig { void }
    def require_game_access!
      redirect_to root_path, alert: "You do not have access to this game." unless policy(game).view?
    end
  end
end
