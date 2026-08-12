xml.instruct! :xml, version: "1.0"
xml.rss(version: "2.0") do
  xml.channel do
    xml.title feed_channel_title(@games, account_level: @account_level)
    xml.link feed_channel_link(@games)
    xml.description feed_channel_description(@games, account_level: @account_level)
    xml.language "en"

    @summaries.each do |summary|
      scene = summary.scene
      game = scene.game
      xml.item do
        xml.title feed_item_title(scene, game, account_level: @account_level)
        xml.link game_scene_url(game, scene)
        xml.guid game_scene_url(game, scene), isPermaLink: true
        xml.pubDate scene.resolved_at.rfc2822 if scene.resolved_at
        xml.description summary.body
      end
    end
  end
end
