# typed: true

module GameExport
  # The reads behind the AI audit CSV. AiGeneration carries no game association
  # by design (the row outlives its asset and users), so a game's rows are
  # resolved at read time: rows are grouped by asset_type and each type's ids are
  # filtered to the game via ASSET_GAME_SCOPES — a new game-level AI asset type
  # is one entry there, not a rewrite. Kept out of Reads so that class stays the
  # game-content reader and this stays the audit-provenance reader.
  module AuditReads
    extend T::Sig

    # For each asset_type an AiGeneration can name, the ids among `ids` whose
    # asset belongs to `game`. Only "SceneSummary" is ever written today.
    ASSET_GAME_SCOPES = T.let(
      {
        "SceneSummary" => lambda do |ids, game|
          SceneSummary.where(id: ids).joins(scene: :game)
                      .where(scenes: { game_id: game.id }).pluck(:id)
        end
      }.freeze,
      T::Hash[String, T.proc.params(ids: T::Array[Integer], game: Game).returns(T::Array[Integer])]
    )

    sig { params(game: Game).returns(T::Array[AiGeneration]) }
    def self.generations_for(game)
      rows = AiGeneration.order(:created_at).to_a
      rows.group_by(&:asset_type).flat_map { |asset_type, group| in_game(asset_type, group, game) }
          .sort_by(&:created_at)
    end

    # The {user_id => display name} map for the requester/funder columns,
    # resolved in one query rather than a find per row. A user deleted since a
    # generation (the audit row outlives them) simply has no entry, so the CSV
    # cell is left blank.
    sig { params(generations: T::Array[AiGeneration]).returns(T::Hash[Integer, String]) }
    def self.names_for(generations)
      ids = generations.flat_map { |generation| [ generation.requested_by_id, generation.funded_by_id ] }.uniq
      User.where(id: ids).includes(:user_profile).to_h { |user| [ user.id, Author.name_for(user) ] }
    end

    # The rows in `group` (all of one asset_type) whose asset belongs to `game`.
    sig { params(asset_type: String, group: T::Array[AiGeneration], game: Game).returns(T::Array[AiGeneration]) }
    def self.in_game(asset_type, group, game)
      scope = ASSET_GAME_SCOPES[asset_type]
      return [] unless scope

      game_asset_ids = scope.call(group.map(&:asset_id), game)
      group.select { |row| game_asset_ids.include?(row.asset_id) }
    end
  end
end
