# frozen_string_literal: true

# gem読み込み
require 'discordrb'
require 'dotenv'
require 'json'
require 'time'

require './config/constants'
require './controller/bot_controller'
require './controller/timer_controller'

# 環境変数読み込み
Dotenv.load
TOKEN = ENV['TOKEN']
CLIENT_ID = ENV['CLIENT_ID'].to_i

bot = Discordrb::Commands::CommandBot.new token: TOKEN, client_id: CLIENT_ID, prefix: '!ae ', discord_api_version: 9
bot_controller = BotController.instance.init(bot)
timer_controller = TimerController.instance.init(bot)

# リアクション検知時
bot.reaction_add do |event|
  bot_controller.reaction_control(event)
end

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
bot.command :roll do |event, *args|
  bot_controller.handle_command(event, args, :roll)
end
bot.command :rand do |event, *args|
  bot_controller.handle_command(event, args, :rand)
end
bot.command :test do |event, *args|
  bot_controller.handle_command(event, args, :test)
end
bot.command :open do |event, *args|
  bot_controller.handle_command(event, args, :open)
end
bot.command :plane do |event, *args|
  bot_controller.handle_command(event, args, :plane)
end
bot.command :prof_sheet do |event, *args|
  bot_controller.handle_command(event, args, :prof_sheet)
end
bot.command :asasore do |event, *args|
  bot_controller.handle_command(event, args, :asasore)
end
bot.command :odai do |event, *args|
  bot_controller.handle_command(event, args, :odai)
end

# ハッシュ検知時の反応
# bot.message(contains: /^(?!.*http)(?!.*<@)(?!.*<#)(?!.*<:)(?!.*<a:)(?!.*<t:)(?!.*[[.*|?.*]])(?!^AA.+A$)[!-~]{19,}$/) do |event|
#   bot_controller.handle_message(event, :hash)
# end

# TwiiterのNSFWサムネイル表示
bot.message(contains: %r{https://twitter.com/([a-zA-Z0-9_]+)/status/([0-9]+)|https://x.com/([a-zA-Z0-9_]+)/status/([0-9]+)}) do |event|
  bot_controller.handle_message(event, :thumb)
end

# Wisdom Guild
bot.message(contains: /{{/) do |event|
  bot_controller.handle_message(event, :wg)
end

# Wisdom Guild
bot.message(contains: /\[\[/) do |event|
  bot_controller.handle_message(event, :dfc)
end

# メッセージリンク展開
bot.message(contains: 'https://discord.com/channels/') do |event|
  bot_controller.handle_message(event, :message_link)
end

# DPZ
bot.message(from: 952298431194488942) do |event|
  bot_controller.handle_message(event, :dpz)
end

# bot.member_join do |event|
#   bot.channel(WELCOME_CHANNEL_ID).send_message("<@!#{event.user.id}>" << Constants::WELCOME_MESSAGE)
# end

bot.heartbeat do
  if $todays_date != Date.today
    $todays_date = Date.today
    # 日付変更時に行う処理
    bot_controller.routine
  end
end

# bot起動
bot.run(true)

# 時限実行のループ起動
loop do
  timer_controller.check_reminder
  timer_controller.check_daily_task
  sleep 30
end

bot.join
