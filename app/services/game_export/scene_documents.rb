# typed: true

module GameExport
  # scene_info.md and posts.md for a single exported scene. Participants and
  # published posts are read by the caller and handed in, so nothing here
  # touches the database.
  module SceneDocuments
    extend T::Sig

    BLANK = ""

    sig { params(scene: Scene, participants: T::Array[SceneParticipant]).returns(String) }
    def self.info(scene, participants)
      [
        "# #{scene.title}",
        BLANK,
        scene.description.presence || "_No description._",
        BLANK,
        *status_lines(scene),
        *parent_lines(scene),
        *participant_lines(participants),
        *resolution_lines(scene)
      ].join("\n")
    end

    sig { params(scene: Scene).returns(T::Array[String]) }
    def self.status_lines(scene)
      resolved = scene.resolved?
      resolved_line = resolved ? [ "**Resolved:** #{T.must(scene.resolved_at).strftime("%Y-%m-%d")}" ] : []

      [
        "**Status:** #{resolved ? "Resolved" : "Active"}",
        "**Created:** #{scene.created_at.strftime("%Y-%m-%d")}",
        *resolved_line,
        BLANK
      ]
    end

    sig { params(scene: Scene).returns(T::Array[String]) }
    def self.parent_lines(scene)
      parent = scene.parent_scene
      return [] unless parent

      [ "## Parent Scene", BLANK, parent.title, BLANK ]
    end

    sig { params(participants: T::Array[SceneParticipant]).returns(T::Array[String]) }
    def self.participant_lines(participants)
      return [] if participants.empty?

      rows = participants.map do |participant|
        "| #{Author.name_for(participant.user)} | #{participant.character&.name || "—"} |"
      end

      [ "## Participants", BLANK, "| Display Name | Character |", "|---|---|", *rows, BLANK ]
    end

    sig { params(scene: Scene).returns(T::Array[String]) }
    def self.resolution_lines(scene)
      resolution = scene.resolution
      return [] unless scene.resolved? && resolution.present?

      [ "## Resolution", BLANK, resolution.to_s, BLANK ]
    end

    sig { params(posts: T::Array[Post]).returns(String) }
    def self.posts(posts)
      return "_No posts yet._\n" if posts.empty?

      posts.flat_map { |post| post_lines(post) }.join("\n")
    end

    sig { params(post: T.untyped).returns(T::Array[String]) }
    def self.post_lines(post)
      ooc = post.is_ooc? ? [ "[Out of Character]" ] : []

      [ post_heading(post), *ooc, BLANK, post.content.to_s, BLANK, "---", BLANK ]
    end

    sig { params(post: T.untyped).returns(String) }
    def self.post_heading(post)
      timestamp = post.created_at.strftime("%Y-%m-%d %H:%M UTC")
      edited = post.last_edited_at.present? ? " (edited)" : ""

      "## #{Author.name_for(post.user)} — #{timestamp}#{edited}"
    end
  end
end
