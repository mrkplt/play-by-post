# typed: strict

# The New Link / Edit Link form: a URL and a short description of what the link
# is. Both are required, and the URL must be an absolute http(s) URL (validated
# on the model). The component derives its rendering mode (new vs edit), labels,
# and back-href from the link it is handed, so the view renders it with just the
# game and the link — no form-construction logic in the template.
class Shared::LinkFormComponent < ApplicationComponent
  extend T::Sig
  include Shared::RecordBackedForm

  sig { params(game: GamePresenter, game_link: GameLinkPresenter).void }
  def initialize(game:, game_link:)
    @game = T.let(game, GamePresenter)
    @game_link = T.let(game_link, GameLinkPresenter)
  end

  sig { returns(GamePresenter) }
  attr_reader :game

  sig { returns(GameLinkPresenter) }
  attr_reader :game_link

  sig { override.returns(GameLinkPresenter) }
  def record
    @game_link
  end

  sig { returns(String) }
  def submit_label
    new_record? ? "Create Link" : "Save"
  end

  sig { returns(String) }
  def back_href
    helpers.game_game_links_path(@game)
  end

  sig { returns(String) }
  def form_id
    new_record? ? "new_game_link_form" : "edit_game_link_#{@game_link.id}_form"
  end
end
