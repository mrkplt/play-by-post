# typed: strict

# View model for a character sheet screen. The sheet's own edit/assign-owner
# capabilities are asked of a policy supplied at construction
# (options[:character_policy]) rather than looked up in the view, so a
# capability rename is chased through one construction point instead of every
# character template. Explicit sigs are declared for everything the character
# form/detail components read — SimpleDelegator passthrough is invisible to
# Sorbet, so a component may not call an undeclared method on this presenter
# even though it would resolve at runtime.
#
# options[:urls] — the constructing controller, used to resolve this
# character's own edit/cancel hrefs so a template never builds a route by
# walking from this presenter to its game (Law of Demeter: a template may
# call one method on the presenter it was handed, not reach through it).
class CharacterPresenter < BasePresenter
  extend T::Sig

  sig { returns(String) }
  def name
    @model.name.to_s
  end

  sig { returns(String) }
  def checkbox_value
    id.to_s
  end

  # The viewer may edit this character sheet.
  sig { returns(T::Boolean) }
  def can_edit?
    @options.fetch(:character_policy).update?
  end

  # Only the GM may reassign a sheet's owner — the character-form's player
  # selector and the roster archive/restore affordance both key off this.
  sig { returns(T::Boolean) }
  def can_assign_owner?
    @options.fetch(:character_policy).assign_owner?
  end

  sig { returns(Game) }
  def game
    @model.game
  end

  # This character's own edit URL — the roster/show screen's Edit link.
  sig { returns(String) }
  def edit_href
    @options.fetch(:urls).edit_game_character_path(game, @model)
  end

  # Where Cancel returns to on the form screens: an unsaved character has no
  # show URL yet, so it goes back to the game; an existing character returns
  # to its own sheet.
  sig { returns(String) }
  def cancel_href
    urls = @options.fetch(:urls)
    return urls.game_path(game) if new_record?

    urls.game_character_path(game, @model)
  end

  sig { returns(String) }
  def content
    @model.content.to_s
  end

  sig { returns(T::Boolean) }
  def content?
    @model.content.present?
  end

  sig { returns(T::Boolean) }
  def archived? = @model.archived?

  sig { returns(T::Boolean) }
  def hidden? = @model.hidden?

  sig { returns(T::Boolean) }
  def new_record? = @model.new_record?

  sig { returns(T.nilable(Integer)) }
  def id = @model.id

  sig { returns(T::Boolean) }
  def errors?
    @model.errors.any?
  end

  sig { returns(T::Array[String]) }
  def error_messages
    @model.errors.full_messages
  end
end
