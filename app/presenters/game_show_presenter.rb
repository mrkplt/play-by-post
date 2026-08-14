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
    game.invitations.pending.order(created_at: :desc).to_a.map do |invitation|
      InvitationPresenter.new(invitation, game: game, urls: @options.fetch(:urls))
    end
  end

  # The game's pages, alphabetised by title — the data behind the Pages tab.
  sig { returns(T::Array[PagePresenter]) }
  def pages
    game.pages.order(:title).to_a.map do |page|
      PagePresenter.new(page, game: game, urls: @options.fetch(:urls))
    end
  end

  # The game's links, newest first — the data behind the Links tab.
  sig { returns(T::Array[GameLinkPresenter]) }
  def links
    game.game_links.order(created_at: :desc).to_a.map do |game_link|
      GameLinkPresenter.new(game_link, game: game, urls: @options.fetch(:urls))
    end
  end

  # The game's uploaded files, newest first, wrapped for
  # Shared::GalleryComponent — each carries its own download/delete URLs and
  # thumbnail markup, resolved from the game/helpers/can_manage supplied here
  # at construction (options[:helpers]).
  sig { returns(T::Array[GameFilePresenter]) }
  def game_files
    game.game_files.includes(file_attachment: :blob).order(created_at: :desc).to_a.map do |gf|
      GameFilePresenter.new(gf, game: game, helpers: @options.fetch(:helpers), can_manage: @model.can_manage?)
    end
  end

  # A blank file record for the Files tab's upload form, wrapped the same way.
  sig { returns(GameFilePresenter) }
  def new_game_file
    GameFilePresenter.new(game.game_files.new, game: game, helpers: @options.fetch(:helpers), can_manage: @model.can_manage?)
  end

  private

  sig { returns(Game) }
  def game
    @model.model
  end
end
