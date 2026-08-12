xml.instruct! :xml, version: "1.0"
xml.rss(version: "2.0") do
  xml.channel do
    xml.title "#{@game.name} — Campaign Log"
    xml.link game_scene_summaries_url(@game)
    xml.description "Scene summaries for #{@game.name}"
    xml.language "en"

    @summaries.each do |summary|
      scene = summary.scene
      xml.item do
        xml.title scene.title
        xml.link game_scene_url(@game, scene)
        xml.guid game_scene_url(@game, scene), isPermaLink: true
        xml.pubDate scene.resolved_at.rfc2822 if scene.resolved_at
        xml.description summary.body
      end
    end
  end
end
