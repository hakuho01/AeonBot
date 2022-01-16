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

# API通信
def get_api(api_uri)
  uri = URI.parse(api_uri)
  response = Net::HTTP.get_response(uri)
  JSON.parse(response.body)
end

# メンション時の反応
bot.mention do |event|
  message = event.message.to_s
  if message.match?('楽天')
    parsed_response = get_api(URLs::RAKUTEN_GENRE)
    random_genre = parsed_response['children'].sample
    genreid = random_genre['child']['genreId']
    request_uri = URLs::RAKUTEN_RANKING + genreid.to_s
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
  elsif message.match?(/wiki/i)
    parsed_response = get_api(URLs::WIKIPEDIA)
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
      api.remove_member("Bot #{TOKEN}", SERVER_ID, event.user.id)
    end
  else
    api.add_member_role("Bot #{TOKEN}", SERVER_ID, event.user.id, ISOLATE_ROLE_ID)
    api.remove_member_role("Bot #{TOKEN}", SERVER_ID, event.user.id, DEPRIVATE_ROLE_ID)
  end
end

# bot起動
bot.run
