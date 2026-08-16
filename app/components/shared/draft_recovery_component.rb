# typed: strict

# The "unsaved draft left behind" notice for a draftable record: the composer
# can disappear (a resolved scene, a navigated-away page) once a draft exists,
# leaving the draft otherwise invisible. Shows the draft content read-only with
# a Discard action, and renders nothing when there is no draft to recover.
#
# Deliberately record-agnostic: it takes the draft presenter, the discard path,
# and the notice text directly rather than a scene and a game, so posts, pages
# and scene summaries all reuse it. Each caller supplies the presenter (any
# presenter exposing #content) and the route it already knows how to build.
class Shared::DraftRecoveryComponent < ApplicationComponent
  extend T::Sig

  sig do
    params(
      draft: T.untyped,
      discard_path: String,
      notice: String
    ).void
  end
  def initialize(draft:, discard_path:, notice:)
    @draft = T.let(draft, T.untyped)
    @discard_path = T.let(discard_path, String)
    @notice = T.let(notice, String)
  end

  sig { returns(T::Boolean) }
  def draft?
    !@draft.nil?
  end

  sig { returns(String) }
  def draft_content
    @draft.content
  end

  sig { returns(String) }
  attr_reader :discard_path

  sig { returns(String) }
  attr_reader :notice
end
