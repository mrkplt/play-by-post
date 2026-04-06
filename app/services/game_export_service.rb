# typed: true

require "zip"

class GameExportService
  extend T::Sig

  sig { params(user: User, games: T::Array[Game]).void }
  def initialize(user, games)
    @user = user
    @games = games
  end

  # Returns a binary string of the zip archive.
  sig { returns(String) }
  def call
    buffer = Zip::OutputStream.write_buffer do |zip|
      if @games.size == 1
        build_game(T.must(@games.first), zip, prefix: root_prefix(@games.first))
      else
        @games.each do |game|
          slug = slugify(game.name)
          build_game(game, zip, prefix: "all-games-export-#{export_date}/#{slug}/")
        end
      end
    end
    buffer.string
  end

  private

  sig { returns(String) }
  def export_date
    Time.current.utc.strftime("%Y-%m-%d")
  end

  sig { params(game: T.nilable(Game)).returns(String) }
  def root_prefix(game)
    return "all-games-export-#{export_date}/" if game.nil?

    "#{slugify(game.name)}-export-#{export_date}/"
  end

  sig { params(game: Game, zip: Zip::OutputStream, prefix: String).void }
  def build_game(game, zip, prefix:)
    membership = game.member_for(@user)
    return unless membership&.active? || membership&.game_master? || membership&.removed?

    scenes = export_scenes_for(game, membership)

    write_readme(zip, prefix, game, scenes)
    write_files_manifest(zip, prefix, game)
    write_scenes(zip, prefix, game, scenes)
    write_characters(zip, prefix, game, scenes)
  end

  sig { params(game: Game, membership: GameMember).returns(T::Array[Scene]) }
  def export_scenes_for(game, membership)
    if membership.game_master?
      game.scenes.includes(:parent_scene, scene_participants: %i[user character], posts: :user).to_a
    elsif membership.removed?
      game.scenes
          .joins(:scene_participants)
          .where(scene_participants: { user_id: @user.id })
          .includes(:parent_scene, scene_participants: %i[user character], posts: :user)
          .to_a
    else
      Scene.visible_to(@user, game)
           .where(game: game)
           .includes(:parent_scene, scene_participants: %i[user character], posts: :user)
           .to_a
    end
  end

  # --- README.md ---

  sig { params(zip: Zip::OutputStream, prefix: String, game: Game, scenes: T::Array[Scene]).void }
  def write_readme(zip, prefix, game, scenes)
    zip.put_next_entry("#{prefix}README.md")
    zip.write(readme_content(game, scenes))
  end

  sig { params(game: Game, scenes: T::Array[Scene]).returns(String) }
  def readme_content(game, scenes)
    members = game.game_members.includes(:user).order(:role, :status)
    active_count = scenes.count { |s| !s.resolved? }
    resolved_count = scenes.count(&:resolved?)

    lines = []
    lines << "# #{game.name}"
    lines << ""
    lines << game.description.presence || "_No description._"
    lines << ""
    lines << "**Exported:** #{Time.current.utc.strftime("%Y-%m-%d %H:%M UTC")}"
    lines << ""
    lines << "## Members"
    lines << ""
    lines << "| Display Name | Role | Status |"
    lines << "|---|---|---|"
    members.each do |m|
      user = m.user
      next unless user

      display = user.display_name.presence || user.email
      role = m.game_master? ? "GM" : "Player"
      status = m.removed? ? "Former" : "Active"
      lines << "| #{display} | #{role} | #{status} |"
    end
    lines << ""
    lines << "## Scenes"
    lines << ""
    lines << "- Active: #{active_count}"
    lines << "- Resolved: #{resolved_count}"
    lines << ""
    lines.join("\n")
  end

  # --- files_manifest.md ---

  sig { params(zip: Zip::OutputStream, prefix: String, game: Game).void }
  def write_files_manifest(zip, prefix, game)
    zip.put_next_entry("#{prefix}files_manifest.md")
    zip.write(files_manifest_content(game))
  end

  sig { params(game: Game).returns(String) }
  def files_manifest_content(game)
    files = game.game_files.includes(file_attachment: :blob).order(:filename)

    lines = []
    lines << "# Game Files"
    lines << ""

    if files.empty?
      lines << "_No files uploaded._"
    else
      lines << "| Filename | Type | Size | Uploaded |"
      lines << "|---|---|---|---|"
      files.each do |gf|
        size = gf.file.attached? ? humanize_bytes(gf.byte_size || 0) : "unknown"
        uploaded = gf.created_at.strftime("%Y-%m-%d")
        lines << "| #{gf.filename} | #{gf.content_type} | #{size} | #{uploaded} |"
      end
      lines << ""
      lines << "_Binary files are not included in this export. The game's GM can download them from the app._"
    end

    lines << ""
    lines.join("\n")
  end

  sig { params(bytes: Integer).returns(String) }
  def humanize_bytes(bytes)
    if bytes >= 1_048_576
      "#{(bytes / 1_048_576.0).round(1)} MB"
    elsif bytes >= 1_024
      "#{(bytes / 1_024.0).round(1)} KB"
    else
      "#{bytes} B"
    end
  end

  # --- Scenes ---

  sig { params(zip: Zip::OutputStream, prefix: String, game: Game, scenes: T::Array[Scene]).void }
  def write_scenes(zip, prefix, game, scenes)
    slug_tracker = T.let({}, T::Hash[String, Integer])

    scenes.sort_by(&:id).each_with_index do |scene, idx|
      number = format("%03d", idx + 1)
      slug = unique_slug(slugify(scene.title), slug_tracker)
      dir = "#{prefix}scenes/#{number}-#{slug}/"

      zip.put_next_entry("#{dir}scene_info.md")
      zip.write(scene_info_content(scene))

      zip.put_next_entry("#{dir}posts.md")
      zip.write(posts_content(scene))
    end
  end

  sig { params(scene: Scene).returns(String) }
  def scene_info_content(scene)
    lines = []
    lines << "# #{scene.title}"
    lines << ""
    lines << scene.description.presence || "_No description._"
    lines << ""

    status = scene.resolved? ? "Resolved" : "Active"
    lines << "**Status:** #{status}"
    lines << "**Created:** #{scene.created_at.strftime("%Y-%m-%d")}"
    if scene.resolved?
      lines << "**Resolved:** #{T.must(scene.resolved_at).strftime("%Y-%m-%d")}"
    end
    lines << ""

    if scene.parent_scene
      lines << "## Parent Scene"
      lines << ""
      lines << T.must(scene.parent_scene).title
      lines << ""
    end

    participants = scene.scene_participants.includes(:user, :character)
    unless participants.empty?
      lines << "## Participants"
      lines << ""
      lines << "| Display Name | Character |"
      lines << "|---|---|"
      participants.each do |sp|
        user = sp.user
        next unless user

        display = user.display_name.presence || user.email
        character = sp.character&.name || "—"
        lines << "| #{display} | #{character} |"
      end
      lines << ""
    end

    if scene.resolved? && scene.resolution.present?
      lines << "## Resolution"
      lines << ""
      lines << scene.resolution.to_s
      lines << ""
    end

    lines.join("\n")
  end

  sig { params(scene: Scene).returns(String) }
  def posts_content(scene)
    published = scene.posts.published.includes(:user).order(:created_at)
    return "_No posts yet._\n" if published.empty?

    lines = T.let([], T::Array[String])
    published.each do |post|
      user = T.must(post.user)
      author = user.display_name.presence || user.email
      timestamp = post.created_at.strftime("%Y-%m-%d %H:%M UTC")
      edited = post.last_edited_at.present? ? " (edited)" : ""

      lines << "## #{author} — #{timestamp}#{edited}"
      lines << "[Out of Character]" if post.is_ooc?
      lines << ""
      lines << post.content.to_s
      lines << ""
      lines << "---"
      lines << ""
    end
    lines.join("\n")
  end

  # --- Characters ---

  sig { params(zip: Zip::OutputStream, prefix: String, game: Game, scenes: T::Array[Scene]).void }
  def write_characters(zip, prefix, game, scenes)
    characters = characters_for(game, scenes)
    slug_tracker = T.let({}, T::Hash[String, Integer])

    characters.each do |character|
      slug = unique_slug(slugify(character.name), slug_tracker)
      dir = "#{prefix}characters/#{slug}/"

      zip.put_next_entry("#{dir}current_sheet.md")
      zip.write(character_sheet_content(character))

      versions = character.character_versions.includes(:edited_by).order(:created_at)
      versions.each_with_index do |version, idx|
        date = version.created_at.strftime("%Y-%m-%d")
        filename = "#{dir}version_history/#{format("v%03d", idx + 1)}-#{date}.md"
        zip.put_next_entry(filename)
        zip.write(character_version_content(version, idx + 1))
      end
    end
  end

  sig { params(game: Game, scenes: T::Array[Scene]).returns(T::Array[Character]) }
  def characters_for(game, scenes)
    scene_ids = scenes.map(&:id)

    participant_char_ids = SceneParticipant
      .where(scene_id: scene_ids)
      .where.not(character_id: nil)
      .pluck(:character_id)

    user_char_ids = game.characters.where(user: @user).pluck(:id)

    all_ids = (participant_char_ids + user_char_ids).uniq
    Character.where(id: all_ids).includes(:user, :character_versions).order(:name).to_a
  end

  sig { params(character: Character).returns(String) }
  def character_sheet_content(character)
    user = T.must(character.user)
    owner = user.display_name.presence || user.email
    lines = []
    lines << "# #{character.name}"
    lines << ""
    lines << "**Owner:** #{owner}"
    lines << "**Hidden:** #{character.hidden? ? "Yes" : "No"}"
    lines << "**Archived:** #{character.archived? ? "Yes" : "No"}"
    lines << ""
    lines << "---"
    lines << ""
    lines << character.content.to_s
    lines << ""
    lines.join("\n")
  end

  sig { params(version: CharacterVersion, number: Integer).returns(String) }
  def character_version_content(version, number)
    date = version.created_at.strftime("%Y-%m-%d")
    editor = T.must(version.edited_by)
    editor_name = editor.display_name.presence || editor.email
    lines = []
    lines << "# Version #{number} — #{date}"
    lines << ""
    lines << "**Edited by:** #{editor_name}"
    lines << ""
    lines << "---"
    lines << ""
    lines << version.content.to_s
    lines << ""
    lines.join("\n")
  end

  # --- Slug helpers ---

  sig { params(text: String).returns(String) }
  def slugify(text)
    text.downcase
        .gsub(/[^a-z0-9\s-]/, "")
        .gsub(/\s+/, "-")
        .gsub(/-+/, "-")
        .strip
        .then { |s| s.empty? ? "untitled" : s }
  end

  sig { params(base: String, tracker: T::Hash[String, Integer]).returns(String) }
  def unique_slug(base, tracker)
    count = tracker[base].to_i
    tracker[base] = count + 1
    count.zero? ? base : "#{base}-#{count + 1}"
  end
end
