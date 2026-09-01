# typed: true

require "zip"

module GameExport
  # The zip layout for one game: which entries exist and where. One instance
  # per game, so the game and prefix are state rather than threaded arguments.
  # The low-level zip mechanics (prefixing, blob streaming, slug de-dup, version
  # history) live in ZipWriter; Archive decides only what goes where.
  class Archive
    extend T::Sig

    # `reads` is duck-typed rather than sig'd as Reads: specs inject an
    # instance_double, which sorbet-runtime rejects against a concrete type.
    sig { params(zip: Zip::OutputStream, reads: T.untyped, game: Game, prefix: String).void }
    def initialize(zip, reads, game:, prefix:)
      @writer = T.let(ZipWriter.new(zip, prefix), ZipWriter)
      @reads = reads
      @game = game
    end

    sig { params(scenes: T::Array[Scene]).void }
    def write_game(scenes)
      write_manifests(scenes)
      write_files
      write_scenes(scenes)
      write_characters(scenes)
      write_pages
    end

    sig { void }
    def write_notebook
      @writer.each_slugged(@reads.notebook_entries_for(@game), :title) do |entry, slug|
        write_prose("notebook/#{slug}", ProseDocuments.notebook_entry(entry), @reads.versions_for(entry))
      end
    end

    private

    sig { params(scenes: T::Array[Scene]).void }
    def write_manifests(scenes)
      @writer.entry("README.md", ReadmeDocument.call(@game, scenes, @reads.members_for(@game)))
      @writer.entry("files_manifest.md", ManifestDocuments.files(@reads.files_for(@game)))
      @writer.entry("links_manifest.md", ManifestDocuments.links(@reads.links_for(@game)))
    end

    # The uploaded files themselves, under files/, alongside the manifest that
    # indexes them. Filenames are slugged and de-duplicated (extension
    # preserved) so two files sharing a name don't collide; a GameFile with no
    # attached blob is skipped.
    sig { void }
    def write_files
      tracker = T.let({}, T::Hash[String, Integer])

      attached_files.each do |game_file|
        name = Slug.unique_filename(game_file.filename, tracker)
        @writer.blob_entry("files/#{name}", game_file.file.blob)
      end
    end

    # The game's uploaded files that actually have a blob to stream.
    sig { returns(T::Array[T.untyped]) }
    def attached_files
      @reads.files_for(@game).select { |game_file| game_file.file.attached? }
    end

    sig { params(scenes: T::Array[Scene]).void }
    def write_scenes(scenes)
      tracker = T.let({}, T::Hash[String, Integer])

      scenes.sort_by(&:id).each_with_index do |scene, index|
        slug = Slug.unique(Slug.call(scene.title), tracker)
        write_scene(scene, "scenes/#{format("%03d", index + 1)}-#{slug}")
      end
    end

    sig { params(scene: Scene, dir: String).void }
    def write_scene(scene, dir)
      @writer.entry("#{dir}/scene_info.md", SceneDocuments.info(scene, @reads.participants_for(scene)))
      @writer.entry("#{dir}/posts.md", SceneDocuments.posts(@reads.published_posts_for(scene)))
    end

    sig { params(scenes: T::Array[Scene]).void }
    def write_characters(scenes)
      @writer.each_slugged(@reads.characters_for(@game, scenes), :name) do |character, slug|
        write_character(character, "characters/#{slug}")
      end
    end

    sig { params(character: Character, dir: String).void }
    def write_character(character, dir)
      @writer.entry("#{dir}/current_sheet.md", CharacterDocuments.sheet(character))
      @writer.version_history(dir, @reads.versions_for(character), &CharacterDocuments.method(:version))
    end

    sig { void }
    def write_pages
      @writer.each_slugged(@reads.pages_for(@game), :title) do |page, slug|
        write_prose("pages/#{slug}", ProseDocuments.page(page), @reads.versions_for(page))
      end
    end

    # Pages and notebook entries share a shape: one prose document plus its
    # version history under the same slugged directory. Passing the renderer as a
    # Method (via &) keeps it out of an inline block nested inside each_slugged.
    sig { params(dir: String, body: String, versions: T::Array[T.untyped]).void }
    def write_prose(dir, body, versions)
      @writer.entry("#{dir}.md", body)
      @writer.version_history(dir, versions, &ProseDocuments.method(:version))
    end
  end
end
