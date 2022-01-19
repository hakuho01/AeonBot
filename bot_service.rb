require 'singleton'
require 'discordrb'
require 'dotenv'
require 'json'

require './config/constants'
require './func/methods'

Dotenv.load
SERVER_ID = ENV['SERVER_ID']
ISOLATE_ROLE_ID = ENV['ISOLATE_ROLE_ID']
DEPRIVATE_ROLE_ID = ENV['DEPRIVATE_ROLE_ID']
IS_TEST_MODE = ENV['IS_TEST_MODE'] == 'true'

class BotService
  def initialize
    @discord_api = Discordrb::API::Server
  end

  def respond_good_morning(event)
    event.respond "<@!#{event.user.id}>" + 'おはよう。'
  end

  def respond_good_night(event)
    event.respond "<@!#{event.user.id}>" + 'おやすみ。'
  end

  def suggest_rakuten(event)
    rakuten event
  end

  def suggest_wikipedia(event)
    wikipedia event
  end

  def respond_mention(event)
    event.respond "<@!#{event.user.id}>" + Constants::Speech::RESPONSE_MENTION.sample
  end

  def judge_detected_hash(event)
    event.respond Constants::Speech::DETECT_HASH
    member_info = @discord_api.resolve_member("Bot #{TOKEN}", SERVER_ID, event.user.id)
    member_role = JSON.parse(member_info)
    if member_role["roles"].include?(ISOLATE_ROLE_ID)
      event.respond Constants::Speech::PURGE
      if IS_TEST_MODE
        event.respond Constants::Speech::PURGE_TEST_MODE
      else
        @discord_api.remove_member("Bot #{TOKEN}", SERVER_ID, event.user.id)
      end
    else
      @discord_api.add_member_role("Bot #{TOKEN}", SERVER_ID, event.user.id, ISOLATE_ROLE_ID)
      @discord_api.remove_member_role("Bot #{TOKEN}", SERVER_ID, event.user.id, DEPRIVATE_ROLE_ID)
    end
  end

end