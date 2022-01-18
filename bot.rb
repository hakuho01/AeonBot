# frozen_string_literal: true

# gem読み込み
require 'discordrb'
require 'dotenv'
require 'json'
require 'net/http'

# 定数ファイル読み込み
require './config/constants'

# メソッドファイル読み込み
require './func/methods'

# 環境変数読み込み
Dotenv.load
TOKEN = ENV['TOKEN']
CLIENT_ID = ENV['CLIENT_ID']
SERVER_ID = ENV['SERVER_ID']
ISOLATE_ROLE_ID = ENV['ISOLATE_ROLE_ID']
DEPRIVATE_ROLE_ID = ENV['DEPRIVATE_ROLE_ID']
IS_TEST_MODE = ENV['IS_TEST_MODE'] == 'true'
IS_LOCAL = ENV['IS_LOCAL']

bot = Discordrb::Commands::CommandBot.new token: TOKEN, client_id: CLIENT_ID, prefix: '!ae '
api = Discordrb::API::Server

# メンション時の反応
bot.mention do |event|
  if IS_LOCAL
    # 開発時はここに書くとサーバーで動いてる死天使本体が発火しなくなるはず
  else
    message = event.message.to_s
    if message.match?(/おはよ|おは〜|おはー|good morning/i)
      event.respond str.concat("<@!#{event.user.id}>",'おはよう。')
    elsif message.match?(/おやす|おやす〜|おやすー|good night/i)
      event.respond str.concat("<@!#{event.user.id}>",'おやすみ。')
    elsif message.match?('楽天')
      rakuten(event)
    elsif message.match?(/wiki/i)
      wikipedia(event)
    else
      event.respond "<@!#{event.user.id}>" + Constants::Speech::RESPONSE_MENTION.sample
    end
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
