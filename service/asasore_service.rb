# frozen_string_literal: true

require 'nokogiri'

class AsasoreService < Component
  def asasore_theme(event)
    html = URI.open(Constants::URLs::ASASORE).read
    doc = Nokogiri::HTML.parse(html)
    theme = doc.at_css('#wrap-question').text
    event.send_embed do |embed|
      embed.title = theme
      embed.colour = 0xFF00FF
    end
  end
end
