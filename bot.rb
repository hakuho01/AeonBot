# frozen_string_literal: true

# gem読み込み
require 'discordrb'
require 'dotenv'
require 'json'
require 'time'

require './bot_controller'
require './model/reminder'

# 環境変数読み込み
Dotenv.load
TOKEN = ENV['TOKEN']
CLIENT_ID = ENV['CLIENT_ID']

bot = Discordrb::Commands::CommandBot.new token: TOKEN, client_id: CLIENT_ID, prefix: '!ae '
controller = BotController.new

# メンション時の反応
bot.mention do |event|
  controller.handle_mention(event)
end

bot.command :remind do |event, *args|
  controller.handle_command(event, args, :remind)
end

# ハッシュ検知時の反応
bot.message(contains: /^(?!.*http)(?!.*<@)(?!.*<#)(?!.*<:)(?!.*<a:)(?!.*<t:)(?!^AA.+A$)[!-~]{19,}$/) do |event|
  controller.handle_message(event, :hash)
end

# bot起動
bot.run(true)

# リマインダ起動
controller.wait_reminder

bot.join