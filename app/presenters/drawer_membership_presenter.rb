# typed: strict

# One game row in the global nav drawer: the game's name, whether it is the
# row the viewer is currently looking at, and which status glyph it carries.
#
# The drawer component previously received raw GameMember rows and worked out
# `game_master?` / `removed?` itself — a component deciding what to show rather
# than how to show it. Those facts are display logic and live here; the
# component only maps `status_icon` to a glyph and `active?` to a CSS class.
class DrawerMembershipPresenter < BasePresenter
  extend T::Sig

  sig { returns(String) }
  def game_name
    @model.game.name
  end

  # The slug this row links to, for the drawer's `game_path(...)`. GamesController#show
  # looks a game up by slug (`find_by!(slug:)`), so the drawer must link by slug, not id —
  # `game_path(game_id)` yields `/games/<id>`, which no game's slug matches and 404s.
  sig { returns(String) }
  def game_slug
    @model.game.to_param
  end

  # The game this row belongs to, for matching against the request's active_game_id.
  sig { returns(Integer) }
  def game_id
    @model.game_id
  end

  # True when this row is the game the viewer is currently in — the drawer
  # highlights it. `active_game_id` is supplied at construction because it is a
  # fact about the request, not about the membership.
  sig { returns(T::Boolean) }
  def active?
    active_game_id = @options.fetch(:active_game_id)
    !active_game_id.nil? && @model.game_id == active_game_id
  end

  # Which status glyph this row shows: :crown (viewer is GM), :moon (former or
  # removed — dormant but still browsable), or :plain (ordinary player game).
  sig { returns(Symbol) }
  def status_icon
    return :crown if @model.game_master?
    return :moon if @model.removed?

    :plain
  end
end
