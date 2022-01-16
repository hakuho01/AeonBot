# frozen_string_literal: true

# gem読み込み
require 'discordrb'
require 'dotenv'
require 'json'
require 'net/http'

# 定数ファイル読み込み
require './config/constants'

# 環境変数読み込み
Dotenv.load
TOKEN = ENV['TOKEN']
CLIENT_ID = ENV['CLIENT_ID']
SERVER_ID = ENV['SERVER_ID']
ISOLATE_ROLE_ID = ENV['ISOLATE_ROLE_ID']
DEPRIVATE_ROLE_ID = ENV['DEPRIVATE_ROLE_ID']
IS_TEST_MODE = ENV['IS_TEST_MODE'] == 'true'

bot = Discordrb::Commands::CommandBot.new token: TOKEN, client_id: CLIENT_ID, prefix: '!ae '
api = Discordrb::API::Server

# メンション時の反応
bot.mention do |event|
  message = event.message.to_s
  if message.match?('楽天')
    uri = URI.parse('https://app.rakuten.co.jp/services/api/IchibaGenre/Search/20140222?applicationId=1081731812152273419&genreId=0')
    response = Net::HTTP.get_response(uri)
    parsed_response = JSON.parse(response.body)
    random_genre = parsed_response['children'].sample
    genreid = random_genre['child']['genreId']
    request_uri = 'https://app.rakuten.co.jp/services/api/IchibaItem/Ranking/20170628?format=json&genreId=' + genreid.to_s + '&applicationId=1081731812152273419'
    uri = URI.parse(request_uri)
    response = Net::HTTP.get_response(uri)
    parsed_response = JSON.parse(response.body)
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
      embed.image = Discordrb::Webhooks::EmbedImage.new(url: "#{product_image}")
    end
  elsif message.match?(/wiki/i)
    uri = URI.parse('https://ja.wikipedia.org/w/api.php?format=json&action=query&generator=random&grnnamespace=0&prop=info&inprop=url&indexpageids')
    response = Net::HTTP.get_response(uri)
    parsed_response = JSON.parse(response.body)
    pageid = parsed_response['query']['pageids']
    wikipedia_url = parsed_response['query']['pages'][pageid[0]]['fullurl']
    wikipedia_title = parsed_response['query']['pages'][pageid[0]]['title']
    event.send_embed do |embed|
      embed.title = wikipedia_title
      embed.url = wikipedia_url
      embed.colour = 0xFFFFFF
    end
  else
    event.respond "<@!#{event.user.id}>" + Constants::Speech::RESPONSE_MENTION.sample
  end
end

# ハッシュ検知時の反応
bot.message(contains: /^(?!.*http)(?!.*<@)(?!.*<#)(?!.*<:)(?!.*<a:)(?!.*<t:)(?!^AA.+A$)[!-~]{19,}$/) do |event|
  event.respond Constants::Speech::DETECT_HASH
  member_info = api.resolve_member("Bot #{TOKEN}", SERVER_ID, event.user.id)
  member_role = JSON.parse(member_info)
  if member_role["roles"].include?(ISOLATE_ROLE_ID)
    event.respond Constants::Speech::PURGE
    if IS_TEST_MODE
      event.respond Constants::Speech::PURGE_TEST_MODE
    else
      # api.remove_member("Bot #{TOKEN}", SERVER_ID, event.user.id)
    end
  else
    api.add_member_role("Bot #{TOKEN}", SERVER_ID, event.user.id, ISOLATE_ROLE_ID)
    api.remove_member_role("Bot #{TOKEN}", SERVER_ID, event.user.id, DEPRIVATE_ROLE_ID)
  end
end

# bot起動
bot.run
