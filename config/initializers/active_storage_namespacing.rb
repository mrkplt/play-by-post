# typed: false

# Namespaces derived Active Storage assets under key prefixes:
#   variants/  — VariantWithRecord thumbnails
#   previews/  — preview images extracted from PDFs (source for the thumbnails)
#
# Primary uploads (game files, export archives, scene/post images) are handled
# by AttachmentUploader, which builds each blob via create_and_upload! with an
# explicit kind-prefixed key.
#
# Derived assets are created by Active Storage itself, bypassing that service:
#   * Thumbnails: VariantWithRecord#create_or_find_record attaches the variant
#     image from a Hash.
#   * PDF previews: Preview#process attaches the extracted image (yielded by the
#     previewer as a Hash) to blob.preview_image.
# Active Storage's Hash attachable path forwards a `key:` straight to the blob,
# so we merge a prefixed key into each Hash — public `attach` `key:` argument
# only, no blob internals. Derived assets carry no custom metadata.
#
# Existing blobs keep their original flat keys — this affects new uploads only.
#
# Guarded by SECRET_KEY_BASE_DUMMY: that env var marks the `assets:precompile`
# run in the Docker build image, where no credentials (and thus no storage
# bucket) are configured. Referencing these Active Storage classes there forces
# the R2/S3 service to resolve a nil bucket and aborts the build with
# `ArgumentError: missing required option :name`. Neither variants nor previews
# are produced during asset precompilation, so skipping in that context is safe.

unless ENV["SECRET_KEY_BASE_DUMMY"]
  Rails.application.config.to_prepare do
    prefixed_key = lambda do |prefix|
      "#{prefix}/#{ActiveStorage::Blob.generate_unique_secure_token(length: ActiveStorage::Blob::MINIMUM_TOKEN_LENGTH)}"
    end

    ActiveStorage::VariantWithRecord.prepend(Module.new do
      define_method(:create_or_find_record) do |image:|
        super(image: image.merge(key: prefixed_key.call("variants")))
      end
    end)

    ActiveStorage::Preview.prepend(Module.new do
      # The previewer yields the extracted image as an attachable Hash to
      # image.attach; wrap the block to merge a "previews/"-prefixed key in.
      define_method(:process) do
        previewer.preview(service_name: blob.service_name) do |attachable|
          ActiveRecord::Base.connected_to(role: ActiveRecord.writing_role) do
            image.attach(attachable.merge(key: prefixed_key.call("previews")))
          end
        end
      end
    end)
  end
end
