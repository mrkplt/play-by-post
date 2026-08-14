# typed: strict

# View model for GamesController#show's Scenes/Roster panels: the active
# scenes list and the character/GM/banned-member rows. Wraps a GamePresenter
# — composition, not duplication — split out from GameShowPresenter (which
# keeps the Files/Pages/Links/Notebook tabs) purely to keep each presenter
# under the project's file-length ceiling.
class GameRosterPresenter < BasePresenter
  extend T::Sig

  sig { params(model: GamePresenter, options: T.untyped).void }
  def initialize(model, **options)
    super
  end




  # Active characters visible to the viewer, one presenter per row, for the
  # Roster tab's character list.
  sig { returns(T::Array[RosterCharacterPresenter]) }
  def roster_characters
    @roster_characters ||= T.let(build_roster_characters, T.nilable(T::Array[RosterCharacterPresenter]))
  end

  # Archived characters visible to the viewer but hidden from the roster —
  # surfaced only as a count ("N inactive characters hidden").
  sig { returns(Integer) }
  def inactive_character_count
    @inactive_character_count ||= T.let(
      game.characters.archived.visible_to(viewer, game).count,
      T.nilable(Integer)
    )
  end

  # Banned members, GM-only — empty for a non-manager so the section never
  # renders for a player. One presenter per row.
  sig { returns(T::Array[BannedMemberPresenter]) }
  def banned_members
    @banned_members ||= T.let(build_banned_members, T.nilable(T::Array[BannedMemberPresenter]))
  end

  private

  sig { returns(Game) }
  def game
    @model.model
  end

  sig { returns(User) }
  def viewer
    @options.fetch(:current_user)
  end





  sig { returns(T::Array[RosterCharacterPresenter]) }
  def build_roster_characters
    removed_user_ids = game.game_members.where(status: "removed").pluck(:user_id).to_set

    game.characters.active.visible_to(viewer, game).includes(:user).order(:name).to_a.map do |character|
      RosterCharacterPresenter.new(character, removed: removed_user_ids.include?(character.user_id))
    end
  end

  sig { returns(T::Array[BannedMemberPresenter]) }
  def build_banned_members
    return [] unless @model.can_manage?

    game.game_members.where(status: "banned").includes(:user).to_a.map { |member| BannedMemberPresenter.new(member) }
  end
end
