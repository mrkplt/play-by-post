# typed: strict

module Posts
  # A participant's in-progress draft for a scene. The composer autosaves here
  # over JSON, and discarding returns to the scene; publishing is
  # PostsController#create's job, which promotes the same record.
  class DraftsController < ApplicationController
    extend T::Sig
    include PostScoped

    before_action :require_participant!
    before_action :require_active_member_for_write!, only: %i[save]
    after_action :verify_authorized
    sig { void }
    def save
      authorize scene.posts.new, :participate?
      result = draft.save(content: params.dig(:post, :content), is_ooc: params.dig(:post, :is_ooc))
      saved = result.draft

      if result.saved
        render json: { id: saved.id }, status: :ok
      else
        render json: { errors: saved.errors.full_messages }, status: :unprocessable_content
      end
    end

    sig { void }
    def discard
      authorize scene.posts.new, :participate?
      draft.discard
      redirect_to game_scene_path(game, scene), notice: "Draft discarded."
    end

    private

    sig { returns(PostDraft) }
    def draft
      PostDraft.new(scene, current_user)
    end

    sig { void }
    def require_participant!
      return if policy(scene.posts.new).participate?

      redirect_to game_scene_path(game, scene), alert: "You are not a participant in this scene."
    end

    sig { void }
    def require_active_member_for_write!
      require_active_member!(game)
    end
  end
end
