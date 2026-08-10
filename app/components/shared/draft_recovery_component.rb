# typed: strict

# The "unsaved draft" notice on a resolved scene: the composer disappears once
# a scene resolves, so a draft left behind is otherwise invisible. Shows the
# draft content read-only and a Discard Draft action. Renders nothing when
# there is no draft to recover.
class Shared::DraftRecoveryComponent < ApplicationComponent
  extend T::Sig

  sig { params(game: Game, scene: Scene, draft: T.nilable(Post)).void }
  def initialize(game:, scene:, draft:)
    @game = T.let(game, Game)
    @scene = T.let(scene, Scene)
    @draft = T.let(draft, T.nilable(Post))
  end

  sig { returns(T::Boolean) }
  def draft?
    @draft.present?
  end

  sig { returns(String) }
  def draft_content
    T.must(@draft).content.to_s
  end

  sig { returns(String) }
  def discard_path
    helpers.discard_draft_game_scene_posts_path(@game, @scene)
  end
end
