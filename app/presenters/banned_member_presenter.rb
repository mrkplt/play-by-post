# typed: strict

# One row of the game view's GM-only Banned section: a banned membership, with
# the same display name doubling as both the row's name and its "Played by"
# subtitle (there is no character to show for a banned player).
class BannedMemberPresenter < BasePresenter
  extend T::Sig

  sig { params(model: GameMember, options: T.untyped).void }
  def initialize(model, **options)
    super
  end

  sig { returns(GameMember) }
  def member
    @model
  end

  sig { returns(String) }
  def display_name
    UserPresenter.new(@model.user).display_name_or_email
  end
end
