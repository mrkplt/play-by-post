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
module AttachmentUploader
  extend T::Sig

  # Object-key prefixes, one per kind.
  KEY_PREFIXES = T.let({
    "game_file" => "game_files",
    "export" => "exports"
  }.freeze, T::Hash[String, String])

  # Who the attachment belongs to. Grouped so callers pass one owner object
  # instead of two loose (user, game) params. Built via .build (not .new) so
  # both keys are optional — Data's generated .new requires every member.
  Owner = Data.define(:user, :game) do
    extend T::Sig

    sig { params(user: T.nilable(User), game: T.nilable(Game)).returns(AttachmentUploader::Owner) }
    def self.build(user: nil, game: nil)
      new(user: user, game: game)
    end
  end

  # How the attachment is named/scoped for metadata. Grouped for the same
  # reason as Owner. Built via .build so both keys are optional.
  Naming = Data.define(:original_filename, :export_scope) do
    extend T::Sig

    sig do
      params(original_filename: T.nilable(String), export_scope: T.nilable(String))
        .returns(AttachmentUploader::Naming)
    end
    def self.build(original_filename: nil, export_scope: nil)
      new(original_filename: original_filename, export_scope: export_scope)
    end
  end

  # The kind/provenance data recorded as R2 custom metadata, grouped so
  # #attach and #build_metadata take one object instead of a five-way
  # parameter list. Built via .build (not .new) so owner/naming are optional —
  # Data's generated .new requires every member.
  Context = Data.define(:kind, :owner, :naming) do
    extend T::Sig

    sig do
      params(
        kind: String,
        owner: AttachmentUploader::Owner,
        naming: AttachmentUploader::Naming
      ).returns(AttachmentUploader::Context)
    end
    def self.build(kind:, owner: Owner.build, naming: Naming.build)
      new(kind: kind, owner: owner, naming: naming)
    end
  end

  sig { params(attachment: T.untyped, attachable: T.untyped, context: AttachmentUploader::Context).void }
  def self.attach(attachment:, attachable:, context:)
    prefix = KEY_PREFIXES.fetch(context.kind)
    metadata = build_metadata(context)
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
      [ uploaded_file_io(attachable), attachable.original_filename, attachable.content_type ]
    end
  end

  # ActionDispatch::Http::UploadedFile is the shape a controller receives from
  # params for a real multipart upload, and exposes #open (the backing
  # Tempfile's IO). Every other attachable (a raw Tempfile, or
  # Rack::Test::UploadedFile passed directly to .normalize in specs) is
  # already IO-ready as-is. Matched by class rather than respond_to? so this
  # isn't a manual method-existence dispatch.
  sig { params(attachable: T.untyped).returns(T.untyped) }
  def self.uploaded_file_io(attachable)
    case attachable
    in ActionDispatch::Http::UploadedFile
      attachable.open
    else
      attachable
    end
  end

  sig { params(context: AttachmentUploader::Context).returns(T::Hash[String, String]) }
  def self.build_metadata(context)
    owner = context.owner
    naming = context.naming

    {
      "kind" => context.kind,
      "game-id" => owner.game&.id&.to_s,
      "user-id" => owner.user&.id&.to_s,
      "uploaded-at" => Time.current.utc.iso8601,
      "original-filename" => naming.original_filename,
      "export-scope" => naming.export_scope
    }.compact
  end
end
