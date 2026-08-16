# typed: strict

# View model for GamesController#show's Files/Pages/Links/Notebook tabs.
# Roster/Scenes-panel concerns live on the sibling GameRosterPresenter, split
# out purely to keep each presenter under the project's file-length ceiling.
# Wraps a GamePresenter — composition, not duplication.
class GameShowPresenter < BasePresenter
  extend T::Sig

  sig { params(model: GamePresenter, options: T.untyped).void }
  def initialize(model, **options)
    super
  end

  # Outstanding (unaccepted) invitations for this game, newest first — the data
  # behind the GM-only invite panel on the Roster tab.
  sig { returns(T::Array[InvitationPresenter]) }
  def pending_invitations
    @pending_invitations ||= T.let(
      game.invitations.pending.order(created_at: :desc).to_a.map do |invitation|
        InvitationPresenter.new(invitation, game: game, urls: @options.fetch(:urls))
      end,
      T.nilable(T::Array[InvitationPresenter])
    )
  end

  # The game's pages, alphabetised by title — the data behind the Pages tab.
  # A draft page is visible only to a GM (who authored it); non-managers see
  # only published pages, so an in-progress page never leaks to players.
  sig { returns(T::Array[PagePresenter]) }
  def pages
    @pages ||= T.let(
      visible_pages.order(:title).to_a.map do |page|
        PagePresenter.new(page, game: game, urls: @options.fetch(:urls))
      end,
      T.nilable(T::Array[PagePresenter])
    )
  end

  # The game's links, newest first — the data behind the Links tab.
  sig { returns(T::Array[GameLinkPresenter]) }
  def links
    @links ||= T.let(
      game.game_links.order(created_at: :desc).to_a.map do |game_link|
        GameLinkPresenter.new(game_link, game: game, urls: @options.fetch(:urls))
      end,
      T.nilable(T::Array[GameLinkPresenter])
    )
  end

  # The game's uploaded files, newest first, wrapped for
  # Shared::GalleryComponent — each carries its own download/delete URLs and
  # thumbnail markup, resolved from the game/helpers/can_manage supplied here
  # at construction (options[:helpers]).
  sig { returns(T::Array[GameFilePresenter]) }
  def game_files
    @game_files ||= T.let(
      game.game_files.includes(file_attachment: :blob).order(created_at: :desc).to_a.map do |gf|
        GameFilePresenter.new(gf, game: game, helpers: @options.fetch(:helpers), can_manage: @model.can_manage?)
      end,
      T.nilable(T::Array[GameFilePresenter])
    )
  end

  sig { returns(T::Boolean) }
  def game_files?
    game_files.any?
  end

  # A blank file record for the Files tab's upload form, wrapped the same way.
  sig { returns(GameFilePresenter) }
  def new_game_file
    GameFilePresenter.new(game.game_files.new, game: game, helpers: @options.fetch(:helpers), can_manage: @model.can_manage?)
  end

  private

  # Pages this viewer may see: a GM sees every page including their own drafts;
  # anyone else sees only published pages. Untyped because the association proxy
  # and its scope are not statically modelled here — the relation is only ever
  # ordered and enumerated by #pages.
  sig { returns(T.untyped) }
  def visible_pages
    scope = game.pages
    @model.can_manage? ? scope : scope.published
  end

  sig { returns(Game) }
  def game
    @model.model
  end
end
