# frozen_string_literal: true

# gem読み込み
require 'discordrb'
require 'dotenv'
require 'json'
require 'time'

require './controller/bot_controller'
require './controller/daily_task_controller'
require './model/reminder'

# 環境変数読み込み
Dotenv.load
TOKEN = ENV['TOKEN']
CLIENT_ID = ENV['CLIENT_ID'].to_i

bot = Discordrb::Commands::CommandBot.new token: TOKEN, client_id: CLIENT_ID, prefix: '!ae '
bot_controller = BotController.new(bot)
daily_task_controller = DailyTaskController.new(bot)

# メンション時の反応
bot.mention do |event|
  bot_controller.handle_mention(event)
end

bot.command :remind do |event, *args|
  bot_controller.handle_command(event, args, :remind)
end

bot.command :prof do |event, *args|
  bot_controller.handle_command(event, args, :profile)
end

# ハッシュ検知時の反応
bot.message(contains: /^(?!.*http)(?!.*<@)(?!.*<#)(?!.*<:)(?!.*<a:)(?!.*<t:)(?!^AA.+A$)[!-~]{19,}$/) do |event|
  bot_controller.handle_message(event, :hash)
end

# bot起動
bot.run(true)

# リマインダ起動
loop do
  bot_controller.check_reminder
  daily_task_controller.check_daily_task
  sleep 30
end

bot.join
