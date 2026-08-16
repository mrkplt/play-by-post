# typed: true

# A point-in-time snapshot of a notebook entry's title and body, written by
# Versionable::Model on every save, with the editor who made the change.
class NotebookEntryVersion < ApplicationRecord
  extend T::Sig

  belongs_to :notebook_entry
  belongs_to :edited_by, class_name: "User"
end
