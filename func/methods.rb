# frozen_string_literal: true
require './config/constants'

require 'net/http'
require 'open-uri'
require 'nokogiri'

# API通信
def get_api(api_uri)
  uri = URI.parse(api_uri)
  response = Net::HTTP.get_response(uri)
  JSON.parse(response.body)
end

# 楽天
def rakuten(c)
  parsed_response = get_api(Constants::URLs::RAKUTEN_GENRE)
  random_genre = parsed_response['children'].sample
  genreid = random_genre['child']['genreId']
  request_uri = Constants::URLs::RAKUTEN_RANKING + genreid.to_s
  parsed_response = get_api(request_uri)
  product = parsed_response['Items'].sample
  product_name = product['Item']['itemName']
  product_price = product['Item']['itemPrice']
  product_image = product['Item']['mediumImageUrls'][0]['imageUrl']
  product_url = product['Item']['itemUrl']
  c.send_embed do |embed|
    embed.title = product_name
    embed.description = "￥#{product_price}"
    embed.url = product_url
    embed.colour = 0xBF0000
    embed.image = Discordrb::Webhooks::EmbedImage.new(url: product_image.to_s)
  end
end

# wikipedia
def wikipedia(c)
  parsed_response = get_api(Constants::URLs::WIKIPEDIA)
  pageid = parsed_response['query']['pageids']
  wikipedia_url = parsed_response['query']['pages'][pageid[0]]['fullurl']
  wikipedia_title = parsed_response['query']['pages'][pageid[0]]['title']
  c.send_embed do |embed|
    embed.title = wikipedia_title
    embed.url = wikipedia_url
    embed.colour = 0xFFFFFF
  end
end

# 朝それ
def asasore_theme(event)
  html = URI.open(Constants::URLs::ASASORE).read
  doc = Nokogiri::HTML.parse(html)
  theme = doc.at_css('#wrap-question').text
  event.send_embed do |embed|
    embed.title = theme
    embed.colour = 0xFF00FF
  end
end
