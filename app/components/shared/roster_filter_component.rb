# typed: strict

# The filterable Characters list on the game roster panel: a search box over the
# character rows, under `roster-filter` control. The controller hides rows whose
# `data-roster-name` doesn't match the query — purely presentational, no server
# round-trip. Only the character rows are filter targets; the banned/invite
# sections live outside this component because they are not part of the filter.
#
# Owns the section: the search box, the "Characters" header and New Character
# link, the character rows (each a filter target), the empty-state, and the
# inactive-count line. Takes the roster presenter and the New Character path —
# presentation-ready data, no raw models.
class Shared::RosterFilterComponent < ApplicationComponent
  extend T::Sig

  # `roster` is duck-typed to the GameRosterPresenter interface (untyped so a
  # spec can pass an instance_double); the reader documents the contract.
  sig { params(roster: T.untyped, new_character_path: String).void }
  def initialize(roster:, new_character_path:)
    @roster = roster
    @new_character_path = new_character_path
  end

  sig { returns(T.untyped) }
  attr_reader :roster

  sig { returns(String) }
  attr_reader :new_character_path
end
