# typed: strict

# One row of the game view's GM-only Banned section: a banned membership, with
# the same display name doubling as both the row's name and its "Played by"
# subtitle (there is no character to show for a banned player). `game:` and
# `urls:` (the constructing controller) are supplied at construction so the
# presenter never hands the template a raw model to build a route from, and
# never builds a route helper of its own.
class BannedMemberPresenter < BasePresenter
  extend T::Sig

  sig { params(model: GameMember, options: T.untyped).void }
  def initialize(model, **options)
    super
  end

  sig { returns(String) }
  def display_name
    UserPresenter.new(@model.user).display_name_or_email
  end

  # The Unban form's submit route — reinstates this banned member to active.
  sig { returns(String) }
  def unban_path
    @options.fetch(:urls).game_player_management_game_member_path(@options.fetch(:game), @model)
  end
end
