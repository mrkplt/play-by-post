# typed: strict

# View model for a single character sheet snapshot: the version-history show
# screen's timestamp formatting, and — when the presenter is built with an
# `editor_name:` option (the version-history table on a character sheet) —
# the display name of who made the edit, so the table never has to carry a
# raw User or a separate id-keyed hash alongside the versions.
class CharacterVersionPresenter < BasePresenter
  extend T::Sig

  sig { returns(String) }
  def created_at_iso8601
    @model.created_at.iso8601
  end

  sig { returns(String) }
  def created_at_label
    @model.created_at.strftime("%b %-d, %Y %-I:%M %p")
  end

  sig { returns(T::Boolean) }
  def content? = @model.content.present?

  sig { returns(String) }
  def content
    @model.content.to_s
  end

  # The display name of the user who made this edit. Supplied at construction
  # (options[:editor_name]) rather than derived here, so the presenter never
  # has to look up the editing user itself.
  sig { returns(String) }
  def editor_name
    @options.fetch(:editor_name)
  end
end
