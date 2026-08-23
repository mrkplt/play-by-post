# typed: strict

# View model for GamesController#show's Scenes/Roster panels: the active
# scenes list and the character/GM/banned-member rows. Wraps a GamePresenter
# — composition, not duplication — split out from GameShowPresenter (which
# keeps the Files/Pages/Links/Notebook tabs) purely to keep each presenter
# under the project's file-length ceiling.
class GameRosterPresenter < BasePresenter
  extend T::Sig

  POSITIONS = T.let({ true => :last, false => :middle }.freeze, T::Hash[T::Boolean, Symbol])

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

  sig { returns(T::Boolean) }
  def roster_characters?
    roster_characters.any?
  end

  sig { params(index: Integer).returns(Symbol) }
  def roster_character_position(index)
    POSITIONS.fetch(index == roster_characters.length - 1)
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

  # Whether the "N inactive characters hidden" note should show at all.
  sig { returns(T::Boolean) }
  def inactive_characters?
    inactive_character_count.positive?
  end

  # Banned members, GM-only — empty for a non-manager so the section never
  # renders for a player. One presenter per row.
  sig { returns(T::Array[BannedMemberPresenter]) }
  def banned_members
    @banned_members ||= T.let(build_banned_members, T.nilable(T::Array[BannedMemberPresenter]))
  end

  # The GM-only "Banned" section renders only when the viewer manages the
  # game and there is at least one banned member to show.
  sig { returns(T::Boolean) }
  def banned_members_section?
    @model.can_manage? ? banned_members.any? : false
  end

  sig { params(index: Integer).returns(Symbol) }
  def banned_member_position(index)
    POSITIONS.fetch(index == banned_members.length - 1)
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

    game.characters.active.visible_to(viewer, game).includes(:user, :character_images).order(:name).to_a.map do |character|
      RosterCharacterPresenter.new(
        character, removed: removed_user_ids.include?(character.user_id), helpers: @options.fetch(:helpers)
      )
    end
  end

  sig { returns(T::Array[BannedMemberPresenter]) }
  def build_banned_members
    return [] unless @model.can_manage?

    game.game_members.where(status: "banned").includes(user: :user_images).to_a.map do |member|
      BannedMemberPresenter.new(member, game: game, urls: @options.fetch(:urls), helpers: @options.fetch(:helpers))
    end
  end
end
