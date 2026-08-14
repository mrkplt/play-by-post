# typed: strict

# NOTE: superseded by Shared::NavDrawerComponent — no live view renders this
# any more, but its spec/preview keep it in the codebase, so it stays
# gate-clean rather than being left as a violation nobody has to fix.
#
# Takes the viewer's recently-active games as presenters, not models: each
# GamePresenter already carries its own can_manage? (backed by a policy
# injected at construction), so the component never builds or looks up
# authorization itself.
class Shared::SidebarComponent < ApplicationComponent
  extend T::Sig

  sig { params(current_user: T.nilable(UserPresenter), games: T::Array[GamePresenter]).void }
  def initialize(current_user: nil, games: [])
    @current_user = T.let(current_user, T.nilable(UserPresenter))
    @games = T.let(games, T::Array[GamePresenter])
  end

  sig { returns(T::Boolean) }
  def signed_in?
    !@current_user.equal?(nil)
  end

  sig { returns(T::Array[GamePresenter]) }
  attr_reader :games
end
