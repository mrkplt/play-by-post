# typed: strict

# View model for a game's external link: the description/URL pair shown in the
# Links list, plus the edit/delete routes a GM-only row needs. `game:` and
# `urls:` (the constructing controller, which carries every named route
# helper) are supplied at construction so the presenter never builds a route
# helper of its own.
class GameLinkPresenter < BasePresenter
  extend T::Sig

  sig { params(model: GameLink, options: T.untyped).void }
  def initialize(model, **options)
    super
  end

  sig { returns(String) }
  def description
    @model.description
  end

  sig { returns(String) }
  def url
    @model.url
  end

  sig { returns(String) }
  def edit_path
    @options.fetch(:urls).edit_game_game_link_path(@options.fetch(:game), @model)
  end

  sig { returns(String) }
  def delete_path
    @options.fetch(:urls).game_game_link_path(@options.fetch(:game), @model)
  end

  sig { returns(T::Boolean) }
  def new_record?
    @model.new_record?
  end

  sig { returns(T.nilable(Integer)) }
  def id
    @model.id
  end

  sig { returns(T::Boolean) }
  def errors?
    @model.errors.any?
  end

  sig { returns(T::Array[String]) }
  def error_messages
    @model.errors.full_messages
  end
end
