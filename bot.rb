# frozen_string_literal: true

require 'discordrb'
require 'dotenv'
require 'json'

Dotenv.load
TOKEN = ENV['TOKEN']
CLIENT_ID = ENV['CLIENT_ID']
SERVER_ID = ENV['SERVER_ID']
ISOLATE_ROLE_ID = ENV['ISOLATE_ROLE_ID']
DEPRIVATE_ROLE_ID = ENV['DEPRIVATE_ROLE_ID']

bot = Discordrb::Commands::CommandBot.new token: TOKEN, client_id: CLIENT_ID, prefix: '!ae '
api = Discordrb::API::Server

bot.mention do |event|
  event.respond '馴れ馴れしくするな……'
end

bot.message(contains: /^(?!http)(?!.*<@)(?!.*<#)(?!.*<:)(?!.*<a:)(?!.*<t:)[!-~]{19,}$/) do |event|
  event.respond 'ハッシュ値やアクセストークンの疑いがある文字列を検知した。'
  member_info = api.resolve_member("Bot #{TOKEN}", SERVER_ID, event.user.id)
  member_role = JSON.parse(member_info)
  if member_role["roles"].include?(ISOLATE_ROLE_ID)
    event.respond 'さらなる罪を重ねるか……。ならば、粛清する！'
    # api.remove_member("Bot #{TOKEN}", SERVER_ID, event.user.id)
  else
    api.add_member_role("Bot #{TOKEN}", SERVER_ID, event.user.id, ISOLATE_ROLE_ID)
    api.remove_member_role("Bot #{TOKEN}", SERVER_ID, event.user.id, DEPRIVATE_ROLE_ID)
  end
end

bot.run
