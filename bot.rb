require 'discordrb'
require 'dotenv'

Dotenv.load
TOKEN = ENV['TOKEN']
CLIENT_ID = ENV['CLIENT_ID']

bot = Discordrb::Commands::CommandBot.new token: TOKEN, client_id: CLIENT_ID, prefix: '!ae'

# 何かメッセージが入力されたら実行
bot.message do |event|
  event.respond 'Hello, world!'
end

bot.run