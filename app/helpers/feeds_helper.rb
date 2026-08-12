# typed: true

module FeedsHelper
  extend T::Sig

  sig { params(games: T::Array[Game], account_level: T::Boolean).returns(String) }
  def feed_channel_title(games, account_level:)
    return "All Campaigns — Campaign Log" if account_level

    "#{T.must(games.first).name} — Campaign Log"
  end

  sig { params(games: T::Array[Game]).returns(String) }
  def feed_channel_link(games)
    T.unsafe(self).game_scene_summaries_url(T.must(games.first))
  end

  sig { params(games: T::Array[Game], account_level: T::Boolean).returns(String) }
  def feed_channel_description(games, account_level:)
    return "Scene summaries across all your campaigns" if account_level

    "Scene summaries for #{T.must(games.first).name}"
  end

  sig { params(scene: Scene, game: Game, account_level: T::Boolean).returns(String) }
  def feed_item_title(scene, game, account_level:)
    return "[#{game.name}] #{scene.title}" if account_level

    scene.title
  end
end
