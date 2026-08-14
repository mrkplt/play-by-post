# typed: strict

# The "unsaved draft" notice on a resolved scene: the composer disappears once
# a scene resolves, so a draft left behind is otherwise invisible. Shows the
# draft content read-only and a Discard Draft action. Renders nothing when
# there is no draft to recover.
class Shared::DraftRecoveryComponent < ApplicationComponent
  extend T::Sig

  sig { params(game: GamePresenter, scene: ScenePresenter, draft: T.nilable(PostPresenter)).void }
  def initialize(game:, scene:, draft:)
    @game = T.let(game, GamePresenter)
    @scene = T.let(scene, ScenePresenter)
    @draft = T.let(draft, T.nilable(PostPresenter))
  end

  sig { returns(T::Boolean) }
  def draft?
    case @draft
    when nil then false
    else true
    end
  end

  sig { returns(String) }
  def draft_content
    T.must(@draft).content
  end

  sig { returns(String) }
  def discard_path
    @scene.discard_draft_url
  end
end
