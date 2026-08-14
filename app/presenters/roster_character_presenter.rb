# typed: strict

# One row of the game view's Roster tab: a character plus the derived display
# values Shared::RosterRowComponent needs (owner name, removed dimming, avatar
# tone, and the lowercase filter key the roster search filters against).
# `removed` arrives precomputed (options[:removed]) — whether the owning
# player has been removed from the game is a fact about the membership, not
# the character, so the controller looks it up once for the whole roster
# rather than the presenter querying per row.
class RosterCharacterPresenter < BasePresenter
  extend T::Sig

  sig { params(model: Character, options: T.untyped).void }
  def initialize(model, **options)
    super
  end

  sig { returns(String) }
  def character_name
    @model.name
  end

  sig { returns(String) }
  def owner_name
    UserPresenter.new(@model.user).display_name_or_email
  end

  sig { returns(T::Boolean) }
  def removed?
    @options.fetch(:removed)
  end

  sig { returns(Symbol) }
  def avatar_tone
    removed? ? :muted : :gold
  end

  sig { returns(String) }
  def filter_key
    "#{@model.name} #{owner_name}".downcase
  end
end
