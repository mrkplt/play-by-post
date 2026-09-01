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
      @w = T.let(ZipWriter.new(zip, prefix), ZipWriter)
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
      @w.each_slugged(@reads.notebook_entries_for(@game), :title) do |entry, slug|
        @w.entry("notebook/#{slug}.md", ProseDocuments.notebook_entry(entry))
        @w.version_history("notebook/#{slug}", @reads.notebook_entry_versions_for(entry)) do |version, number|
          ProseDocuments.version(version, number)
        end
      end
    end

    private

    sig { params(scenes: T::Array[Scene]).void }
    def write_manifests(scenes)
      @w.entry("README.md", ReadmeDocument.call(@game, scenes, @reads.members_for(@game)))
      @w.entry("files_manifest.md", ManifestDocuments.files(@reads.files_for(@game)))
      @w.entry("links_manifest.md", ManifestDocuments.links(@reads.links_for(@game)))
    end

    # The uploaded files themselves, under files/, alongside the manifest that
    # indexes them. Filenames are slugged and de-duplicated (extension
    # preserved) so two files sharing a name don't collide; a GameFile with no
    # attached blob is skipped.
    sig { void }
    def write_files
      tracker = T.let({}, T::Hash[String, Integer])

      @reads.files_for(@game).each do |game_file|
        next unless game_file.file.attached?

        name = Slug.unique_filename(game_file.filename, tracker)
        @w.blob_entry("files/#{name}", game_file.file.blob)
      end
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
      @w.entry("#{dir}/scene_info.md", SceneDocuments.info(scene, @reads.participants_for(scene)))
      @w.entry("#{dir}/posts.md", SceneDocuments.posts(@reads.published_posts_for(scene)))
    end

    sig { params(scenes: T::Array[Scene]).void }
    def write_characters(scenes)
      @w.each_slugged(@reads.characters_for(@game, scenes), :name) do |character, slug|
        @w.entry("characters/#{slug}/current_sheet.md", CharacterDocuments.sheet(character))
        @w.version_history("characters/#{slug}", @reads.versions_for(character)) do |version, number|
          CharacterDocuments.version(version, number)
        end
      end
    end

    sig { void }
    def write_pages
      @w.each_slugged(@reads.pages_for(@game), :title) do |page, slug|
        @w.entry("pages/#{slug}.md", ProseDocuments.page(page))
        @w.version_history("pages/#{slug}", @reads.page_versions_for(page)) do |version, number|
          ProseDocuments.version(version, number)
        end
      end
    end
  end
end
