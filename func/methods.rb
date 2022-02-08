# frozen_string_literal: true

require './config/constants'

require 'net/http'
require 'open-uri'
require 'nokogiri'
require 'openssl'
require 'cgi'

# API通信
def get_api(api_uri)
  uri = URI.parse(api_uri)
  response = Net::HTTP.get_response(uri)
  JSON.parse(response.body)
end

# 楽天
def rakuten(event)
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
  event.send_embed do |embed|
    embed.title = product_name
    embed.description = "￥#{product_price}"
    embed.url = product_url
    embed.colour = 0xBF0000
    embed.image = Discordrb::Webhooks::EmbedImage.new(url: product_image.to_s)
  end
end

# wikipedia
def wikipedia(event)
  parsed_response = get_api(Constants::URLs::WIKIPEDIA)
  pageid = parsed_response['query']['pageids']
  wikipedia_url = parsed_response['query']['pages'][pageid[0]]['fullurl']
  wikipedia_title = parsed_response['query']['pages'][pageid[0]]['title']
  event.send_embed do |embed|
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

def wisdom_guild(event)
  cardname = event.message.to_s.slice(/{{.*?}}/)[2..-3]
  encoded_cardname = CGI.escape(cardname)
  scryfall = get_api('https://api.scryfall.com/cards/named?fuzzy=' + encoded_cardname)
  encoded_accurate_cardname = CGI.escape(scryfall['name'])
  html = URI.open('http://wonder.wisdom-guild.net/price/' + encoded_accurate_cardname).read
  doc = Nokogiri::HTML.parse(html)
  price = doc.at_css('.wg-wonder-price-summary > .contents > big').text
  name_jp = doc.at_css('.wg-title').text
  event.send_embed do |embed|
    embed.title = name_jp
    embed.url = 'http://wonder.wisdom-guild.net/price/' + encoded_accurate_cardname
    embed.description = price
    embed.colour = 0x6EB0FF
  end
  rescue
    event.respond('……エラー。もう少し丁寧にできないの？')
#      unixtime = Time.now.to_i
#      puts unixtime
#      querystr = 'api_key=hakuho01\nname=' << cardname << '\ntimestamp=' << unixtime.to_s
#      puts querystr
#      api_sig = OpenSSL::HMAC.hexdigest('sha256', 'z9uY6YXsxxK49vtGr8vBedVw', querystr)
#      wgurl = 'http://wonder.wisdom-guild.net/api/card-price/v1/' << '?' << 'api_key=hakuho01&name=' << cardname << '&timestamp=' << unixtime.to_s << '&api_sig=' << api_sig
#      puts wgurl
#      get_api(wgurl)
end
