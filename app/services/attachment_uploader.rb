# typed: true

# Single entry point for the four primary Active Storage uploads (game files,
# export archives, scene images, post images).
#
# It namespaces the object key by kind and attaches R2 Custom Metadata
# (S3 x-amz-meta-*) describing the object, using only public Active Storage API:
# it builds the blob with ActiveStorage::Blob.create_and_upload! passing an
# explicit, kind-prefixed `key:` (documented as the way to control the storage
# folder structure) and `metadata: { custom: ... }` (persisted and mapped to
# x-amz-meta-* by the S3 service), then attaches that blob.
#
# Custom metadata is written once, at upload time, and is immutable afterward.
class AttachmentUploader
  extend T::Sig

  # Object-key prefixes, one per kind.
  KEY_PREFIXES = T.let({
    "game_file" => "game_files",
    "export" => "exports",
    "scene_image" => "scene_images",
    "post_image" => "post_images"
  }.freeze, T::Hash[String, String])

  sig do
    params(
      attachment: T.untyped,
      attachable: T.untyped,
      kind: String,
      user: T.nilable(User),
      game: T.nilable(Game),
      original_filename: T.nilable(String),
      export_scope: T.nilable(String)
    ).void
  end
  def self.attach(attachment:, attachable:, kind:, user: nil, game: nil, original_filename: nil, export_scope: nil)
    prefix = KEY_PREFIXES.fetch(kind)
    metadata = build_metadata(
      kind: kind, user: user, game: game,
      original_filename: original_filename, export_scope: export_scope
    )
    io, filename, content_type = normalize(attachable)

    blob = ActiveStorage::Blob.create_and_upload!(
      key: "#{prefix}/#{ActiveStorage::Blob.generate_unique_secure_token(length: ActiveStorage::Blob::MINIMUM_TOKEN_LENGTH)}",
      io: io,
      filename: filename,
      content_type: content_type,
      metadata: { custom: metadata }
    )
    attachment.attach(blob)
  end

  # Normalizes the supported attachable shapes (uploaded file or io Hash) into
  # the io/filename/content_type trio create_and_upload! expects.
  sig { params(attachable: T.untyped).returns([ T.untyped, String, T.nilable(String) ]) }
  def self.normalize(attachable)
    if attachable.is_a?(Hash)
      [ attachable.fetch(:io), attachable.fetch(:filename), attachable[:content_type] ]
    else
      io = attachable.respond_to?(:open) ? attachable.open : attachable
      [ io, attachable.original_filename, attachable.content_type ]
    end
  end

  sig do
    params(
      kind: String,
      user: T.nilable(User),
      game: T.nilable(Game),
      original_filename: T.nilable(String),
      export_scope: T.nilable(String)
    ).returns(T::Hash[String, String])
  end
  def self.build_metadata(kind:, user:, game:, original_filename:, export_scope:)
    {
      "kind" => kind,
      "game-id" => game&.id&.to_s,
      "user-id" => user&.id&.to_s,
      "uploaded-at" => Time.current.utc.iso8601,
      "original-filename" => original_filename,
      "export-scope" => export_scope
    }.compact
  end
end
