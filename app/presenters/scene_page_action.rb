# typed: strict

# The scene screen's single footer page-action, if any: "Join Scene" for an
# eligible non-participant on an open public scene, "Write Summary" for the GM
# on a resolved scene with no summary yet, or nil (no footer action).
#
# Carries the button's label, route and HTTP method rather than a symbol the
# template has to branch on: the two actions differ only in those three values,
# so handing them back as data collapses the view's case/when into a single
# conditional render. Adding a third footer action is a branch in `for`, not new
# markup in the view.
#
# `route` is the helper name, not a built URL — building one needs persisted
# ids, which would drag this (and every spec touching it) onto the database for
# what is otherwise pure computation. The template resolves it against the scene
# it already has.
#
# `http_method`, not `method` — T::Struct refuses a prop that shadows
# Kernel#method.
class ScenePageAction < T::Struct
  extend T::Sig

  const :label, String
  const :route, Symbol
  const :http_method, T.nilable(Symbol)

  JOIN = T.let(
    ScenePageAction.new(
      label: "Join Scene",
      route: :join_game_scene_participants_path,
      http_method: :post
    ).freeze,
    ScenePageAction
  )

  WRITE_SUMMARY = T.let(
    ScenePageAction.new(
      label: "Write Summary",
      route: :new_game_scene_scene_summary_path,
      http_method: nil
    ).freeze,
    ScenePageAction
  )

  # The same action with its route resolved to a real URL — what the template
  # actually renders, so the view calls no route helper of its own.
  class Resolved < T::Struct
    const :label, String
    const :href, String
    const :http_method, T.nilable(Symbol)
  end

  # `viewer` bundles the three facts about the person looking at the scene, so
  # the rule reads against one subject (the scene) and one actor rather than a
  # flat parameter list.
  class Viewer < T::Struct
    extend T::Sig

    const :can_manage, T::Boolean
    const :is_participant, T::Boolean
    const :membership, T.nilable(GameMember)

    sig { returns(T::Boolean) }
    def active_member?
      membership&.active? || false
    end
  end

  sig { params(scene: Scene, viewer: Viewer).returns(T.nilable(ScenePageAction)) }
  def self.for(scene:, viewer:)
    resolved = scene.resolved?
    manages = viewer.can_manage

    if !viewer.is_participant && !manages && !scene.private? && !resolved && viewer.active_member?
      JOIN
    elsif manages && resolved && scene.scene_summary.blank?
      WRITE_SUMMARY
    end
  end

  # As `for`, with the route resolved to a URL. `route_args` is the caller's
  # url_helpers plus the arguments its route helpers take, bundled because
  # both exist only to turn a route name into an href.
  class RouteArgs < T::Struct
    extend T::Sig

    const :urls, T.untyped
    const :game, Game

    sig { params(route: Symbol, scene: Scene).returns(String) }
    def href_for(route, scene)
      urls.public_send(route, game, scene)
    end
  end

  sig { params(scene: Scene, viewer: Viewer, route_args: RouteArgs).returns(T.nilable(Resolved)) }
  def self.resolved_for(scene:, viewer:, route_args:)
    action = self.for(scene: scene, viewer: viewer)
    return nil unless action

    Resolved.new(
      label: action.label,
      href: route_args.href_for(action.route, scene),
      http_method: action.http_method
    )
  end
end
