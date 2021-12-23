require 'discordrb'
require 'dotenv'

Dotenv.load
TOKEN = ENV['TOKEN']
CLIENT_ID = ENV['CLIENT_ID']
SERVER_ID = ENV['SERVER_ID']
ISOLATE_ROLE_ID = ENV['ISOLATE_ROLE_ID']
DEPRIVATE_ROLE_ID = ENV['DEPRIVATE_ROLE_ID']


bot = Discordrb::Commands::CommandBot.new token: TOKEN, client_id: CLIENT_ID, prefix: '!ae '
api = Discordrb::API::Server

bot.mention do |event|
    event.respond '生きてます。'
end

bot.message(contains: /^(?!http)(?!.*<@)(?!.*<#)(?!.*<:)(?!.*<a:)(?!.*<t:)[!-~]{20,}$/) do |event|
    event.respond 'ハッシュ値やアクセストークンの疑いがある文字列を検知しました。'
    api.add_member_role("Bot #{TOKEN}", SERVER_ID, event.user.id, ISOLATE_ROLE_ID)
    api.remove_member_role("Bot #{TOKEN}", SERVER_ID, event.user.id, DEPRIVATE_ROLE_ID)
end

bot.run