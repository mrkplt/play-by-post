# typed: true

require "zip"

module GameExport
  # The zip layout for one game: which entries exist and where. One instance
  # per game, so the game and prefix are state rather than threaded arguments.
  class Archive
    extend T::Sig

    # `reads` is duck-typed rather than sig'd as Reads: specs inject an
    # instance_double, which sorbet-runtime rejects against a concrete type.
    sig { params(zip: Zip::OutputStream, reads: T.untyped, game: Game, prefix: String).void }
    def initialize(zip, reads, game:, prefix:)
      @zip = zip
      @reads = reads
      @game = game
      @prefix = prefix
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
      each_slugged(@reads.notebook_entries_for(@game), :title) do |entry, slug|
        write_entry("notebook/#{slug}.md", ProseDocuments.notebook_entry(entry))
      end
    end

    private

    sig { params(scenes: T::Array[Scene]).void }
    def write_manifests(scenes)
      write_entry("README.md", ReadmeDocument.call(@game, scenes, @reads.members_for(@game)))
      write_entry("files_manifest.md", ManifestDocuments.files(@reads.files_for(@game)))
      write_entry("links_manifest.md", ManifestDocuments.links(@reads.links_for(@game)))
    end

    # The uploaded files themselves, under files/, alongside the manifest that
    # indexes them. Each blob is streamed into the zip in chunks rather than read
    # whole — a GameFile may be up to 50MB — and filenames are slugged and
    # de-duplicated (extension preserved) so two files sharing a name don't
    # collide. A GameFile with no attached blob is skipped.
    sig { void }
    def write_files
      tracker = T.let({}, T::Hash[String, Integer])

      @reads.files_for(@game).each do |game_file|
        next unless game_file.file.attached?

        name = Slug.unique_filename(game_file.filename, tracker)
        write_blob_entry("files/#{name}", game_file.file.blob)
      end
    end

    sig { params(path: String, content: String).void }
    def write_entry(path, content)
      @zip.put_next_entry("#{@prefix}#{path}")
      @zip.write(content)
    end

    # Streams a blob's bytes into a zip entry in chunks, so a large attachment
    # never sits fully in memory. download's block form yields successive chunks
    # from the storage service.
    sig { params(path: String, blob: T.untyped).void }
    def write_blob_entry(path, blob)
      @zip.put_next_entry("#{@prefix}#{path}")
      blob.download { |chunk| @zip.write(chunk) }
    end

    # One tracker per collection, so repeated titles get -2/-3 rather than
    # colliding on the same path.
    sig do
      params(
        records: T::Array[T.untyped],
        name: Symbol,
        block: T.proc.params(record: T.untyped, slug: String).void
      ).void
    end
    def each_slugged(records, name, &block)
      tracker = T.let({}, T::Hash[String, Integer])
      records.each do |record|
        block.call(record, Slug.unique(Slug.call(record.public_send(name)), tracker))
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
      write_entry("#{dir}/scene_info.md", SceneDocuments.info(scene, @reads.participants_for(scene)))
      write_entry("#{dir}/posts.md", SceneDocuments.posts(@reads.published_posts_for(scene)))
    end

    sig { params(scenes: T::Array[Scene]).void }
    def write_characters(scenes)
      each_slugged(@reads.characters_for(@game, scenes), :name) do |character, slug|
        write_entry("characters/#{slug}/current_sheet.md", CharacterDocuments.sheet(character))
        write_versions(character, slug)
      end
    end

    sig { params(character: Character, slug: String).void }
    def write_versions(character, slug)
      @reads.versions_for(character).each_with_index do |version, index|
        number = index + 1
        date = version.created_at.strftime("%Y-%m-%d")
        path = "characters/#{slug}/version_history/#{format("v%03d", number)}-#{date}.md"

        write_entry(path, CharacterDocuments.version(version, number))
      end
    end

    sig { void }
    def write_pages
      each_slugged(@reads.pages_for(@game), :title) do |page, slug|
        write_entry("pages/#{slug}.md", ProseDocuments.page(page))
      end
    end
  end
end
