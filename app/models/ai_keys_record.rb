# typed: true

# Abstract base for models living in the `ai_keys` database (config/database.yml).
# `connects_to` can only be called on ActiveRecord::Base or an abstract class,
# so AiPrivateKey (the sole model here) descends from this rather than
# ApplicationRecord directly. Kept as its own file/class, not folded into
# AiPrivateKey, so a second ai_keys-database model (if this custody model ever
# grows one) shares the same connection without redeclaring connects_to.
class AiKeysRecord < ApplicationRecord
  self.abstract_class = true

  connects_to database: { writing: :ai_keys, reading: :ai_keys }
end
