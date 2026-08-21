# typed: true

# Abstract base for models living in the `ai_keys` database (config/database.yml).
# `connects_to` can only be called on ActiveRecord::Base or an abstract class,
# so PrivateKey (the sole model here) descends from this rather than
# ApplicationRecord directly. Kept as its own file/class, not folded into
# PrivateKey, so a second ai_keys-database model (if this custody model ever
# grows one) shares the same connection without redeclaring connects_to.
#
# The database name (`ai_keys`, config/database.yml / AI_KEYS_DATABASE_PATH)
# stays AI-prefixed deliberately — see config/database.yml and
# docs/CONFIGURATION.md: renaming the deployed volume/env var is out of scope
# for this de-AI pass. Only the Ruby-side base class name generalizes.
class KeysRecord < ApplicationRecord
  self.abstract_class = true

  connects_to database: { writing: :ai_keys, reading: :ai_keys }
end
