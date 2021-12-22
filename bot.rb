require 'discordrb'
require 'dotenv'

Dotenv.load
TOKEN = ENV['TOKEN']
CLIENT_ID = ENV['CLIENT_ID']
SERVER_ID = ENV['SERVER_ID']
ROLE_ID = ENV['ROLE_ID']

bot = Discordrb::Commands::CommandBot.new token: TOKEN, client_id: CLIENT_ID, prefix: '!ae '
api = Discordrb::API::Server

bot.message(contains: /^(?!http)[!-~]{20,}/) do |event|
  event.respond 'ハッシュ値やアクセストークンの疑いがある文字列を検知しました。'
  api.add_member_role(TOKEN, SERVER_ID, event.user.id, ROLE_ID)
end

bot.run