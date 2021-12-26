# frozen_string_literal: true

# gem読み込み
require 'discordrb'
require 'dotenv'
require 'json'

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
  response_array = Constants::Speech::RESPONSE_MENTION
  event.respond response_array.sample
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
