# typed: true

# A point-in-time snapshot of a page's title and body, written by
# Versionable::Model on every save, with the editor who made the change.
class PageVersion < ApplicationRecord
  extend T::Sig

  belongs_to :page
  belongs_to :edited_by, class_name: "User"
end
