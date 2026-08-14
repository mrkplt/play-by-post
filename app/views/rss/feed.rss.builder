xml.instruct! :xml, version: "1.0"
xml.rss(version: "2.0") do
  xml.channel do
    xml.title "#{@game_presenter.name} — Campaign Log"
    xml.link game_scene_summaries_url(@game_presenter)
    xml.description "Scene summaries for #{@game_presenter.name}"
    xml.language "en"

    @summaries.each do |summary|
      xml.item do
        xml.title summary.scene_title
        xml.link summary.scene_url
        xml.guid summary.scene_url, isPermaLink: true
        xml.pubDate summary.scene_resolved_at_pub_date if summary.scene_resolved_at_pub_date
        xml.description summary.body
      end
    end
  end
end
