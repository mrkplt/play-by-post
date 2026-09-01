# typed: true

require "zip"
require "tempfile"

# Builds the downloadable zip for one or more games. This class owns only the
# top-level shape — the policy gate, the export scope, and each game's root
# prefix. Per-game layout lives in GameExport::Archive, document content in the
# GameExport document modules, and every query in GameExport::Reads.
class GameExportService
  extend T::Sig

  sig { params(user: User, games: T::Array[Game], reads: T.untyped).void }
  def initialize(user, games, reads: GameExport::Reads.new(user))
    @user = user
    @games = games
    @reads = reads
  end

  # Builds the zip on disk and returns it as an open, rewound Tempfile — never
  # an in-memory String. A game's uploaded files can be tens of MB each
  # (GameFile::MAX_SIZE is 50MB) and are streamed straight into the archive, so
  # buffering the whole zip in memory would risk OOM-killing the worker (768m
  # limit). The caller streams the Tempfile to storage and is responsible for
  # closing/unlinking it.
  sig { returns(Tempfile) }
  def call
    tempfile = Tempfile.new([ "game-export", ".zip" ], binmode: true)
    # rubyzip's RBI types the yielded value as IO; at runtime it is a
    # Zip::OutputStream, which is what write_games consumes.
    Zip::OutputStream.open(T.must(tempfile.path)) { |zip| write_games(T.unsafe(zip)) }
    tempfile.rewind
    tempfile
  end

  private

  sig { params(zip: Zip::OutputStream).void }
  def write_games(zip)
    if @games.size == 1
      single = T.must(@games.first)
      build_game(zip, single, prefix: root_prefix(single))
    else
      @games.each { |game| build_game(zip, game, prefix: all_games_prefix(game)) }
    end
  end

  sig { returns(String) }
  def export_date
    Time.current.utc.strftime("%Y-%m-%d")
  end

  sig { params(game: Game).returns(String) }
  def root_prefix(game)
    "#{GameExport::Slug.call(game.name)}-export-#{export_date}/"
  end

  sig { params(game: Game).returns(String) }
  def all_games_prefix(game)
    "all-games-export-#{export_date}/#{GameExport::Slug.call(game.name)}/"
  end

  sig { params(zip: Zip::OutputStream, game: Game, prefix: String).void }
  def build_game(zip, game, prefix:)
    policy = GamePolicy.new(@user, game)
    return unless policy.export?

    archive = GameExport::Archive.new(zip, @reads, game: game, prefix: prefix)
    archive.write_game(@reads.scenes_for(game, policy.export_scene_selection))

    # Notebook content is GM-eyes-only regardless of general export
    # eligibility — gated on the GM check specifically (policy.update? is
    # GamePolicy's GM predicate), not policy.export?, since a player exporting
    # their own visible/participating slice must never receive it.
    archive.write_notebook if policy.update?
  end
end
