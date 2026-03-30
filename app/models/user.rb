class User < ApplicationRecord
  devise :magic_link_authenticatable, :rememberable

  has_one :user_profile, dependent: :destroy
  has_many :game_members, dependent: :destroy
  has_many :games, through: :game_members
  has_many :scene_participants, dependent: :destroy
  has_many :scenes, through: :scene_participants
  has_many :posts, dependent: :destroy
  has_many :characters, dependent: :destroy

  def display_name
    user_profile&.display_name
  end

  def games_by_recent_activity(limit: nil)
    # Get games where user is not removed/banned, ordered by most recent scene activity
    # Uses Arel for safe SQL generation
    query = games
      .where.not("game_members.status" => [ "removed", "banned" ])
      .left_joins(:scenes)
      .select("games.id, games.name, games.created_at, MAX(scenes.updated_at) as latest_activity")
      .group("games.id", "games.name", "games.created_at")
      .order(Arel.sql("COALESCE(MAX(scenes.updated_at), games.created_at) DESC"))

    query = query.limit(limit) if limit
    query
  end
end
