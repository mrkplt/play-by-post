# typed: false

# Namespaces derived Active Storage assets (VariantWithRecord thumbnails and
# PDF previews) under a "variants/" key prefix.
#
# Primary uploads (game files, export archives, scene/post images) are handled
# by AttachmentUploader, which builds each blob via create_and_upload! with an
# explicit kind-prefixed key.
#
# Derived assets are created by Active Storage itself inside
# VariantWithRecord#create_or_find_record, which attaches the variant image from
# a Hash. Active Storage's Hash attachable path forwards a `key:` straight to the
# blob, so we merge a "variants/"-prefixed key into it — using only the public
# attach `key:` argument, no blob internals. Derived assets carry no custom
# metadata.
#
# Existing blobs keep their original flat keys — this affects new uploads only.

Rails.application.config.to_prepare do
  ActiveStorage::VariantWithRecord.prepend(Module.new do
    def create_or_find_record(image:)
      key = "variants/#{ActiveStorage::Blob.generate_unique_secure_token(length: ActiveStorage::Blob::MINIMUM_TOKEN_LENGTH)}"
      super(image: image.merge(key: key))
    end
  end)
end
