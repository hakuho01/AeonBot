# 今は参照してないファイルです
require './config/constants'

require 'open-uri'
require 'nokogiri'

def asasore(event)
  html = URI.open(Constants::URLs::ASASORE).read
  doc = Nokogiri::HTML.parse(html)
  asasore_theme = doc.at_css('#wrap-question').text
  event.send_embed do |embed|
    embed.title = asasore_theme
    embed.colour = 0xFF00FF
  end
end
