require 'singleton'
require 'discordrb'
require 'dotenv'
require 'json'
require 'mini_magick'

require './config/constants'
require './func/methods'
require './util/time_util'
require './repository/reminder_repository'

Dotenv.load
SERVER_ID = ENV['SERVER_ID']
ISOLATE_ROLE_ID = ENV['ISOLATE_ROLE_ID']
DEPRIVATE_ROLE_ID = ENV['DEPRIVATE_ROLE_ID']
IS_TEST_MODE = ENV['IS_TEST_MODE'] == 'true'

class BotService
  def initialize
    @server_api = Discordrb::API::Server
    @channel_api = Discordrb::API::Channel
    @reminder_repository = ReminderRepository.new
  end

  def say_good_morning(event)
    event.respond "<@!#{event.user.id}>" + 'おはよう。'
  end

  def say_good_night(event)
    event.respond "<@!#{event.user.id}>" + 'おやすみ。'
  end

  def suggest_rakuten(event)
    rakuten event
  end

  def suggest_wikipedia(event)
    wikipedia event
  end

  def say_random(event)
    event.respond "<@!#{event.user.id}>" + Constants::Speech::RESPONSE_MENTION.sample
  end

  def judge_detected_hash(event)
    event.respond Constants::Speech::DETECT_HASH
    member_info = @server_api.resolve_member("Bot #{TOKEN}", SERVER_ID, event.user.id)
    member_role = JSON.parse(member_info)
    if member_role["roles"].include?(ISOLATE_ROLE_ID)
      event.respond Constants::Speech::PURGE
      if IS_TEST_MODE
        event.respond Constants::Speech::PURGE_TEST_MODE
      else
        @server_api.remove_member("Bot #{TOKEN}", SERVER_ID, event.user.id)
      end
    else
      @server_api.add_member_role("Bot #{TOKEN}", SERVER_ID, event.user.id, ISOLATE_ROLE_ID)
      @server_api.remove_member_role("Bot #{TOKEN}", SERVER_ID, event.user.id, DEPRIVATE_ROLE_ID)
    end
  end

  def remind(reminder)
    message = "<@!#{reminder.user_id}>" + Constants::Speech::REMIND % reminder.message
    @channel_api.create_message("Bot #{TOKEN}", reminder.channel_id, message)
  end

  def fetch_reminder_list
      return @reminder_repository.fetch_all
  end

  def add_reminder(date_str, time_str, message, event)
    reminder = Reminder.new(
      @reminder_repository.get_next_id,
      TimeUtil::parse_date_time(date_str, time_str),
      message,
      event.channel.id,
      event.user.id
    )
    @reminder_repository.add(reminder)
    event.respond "<@!#{event.user.id}>" + Constants::Speech::ADD_REMINDER % [reminder.time.strftime('%Y年%-m月%-d日の%-H時%-M分'), message]
  end

  def deny_too_long_reminder(event)
    event.respond "<@!#{event.user.id}>" + Constants::Speech::DENY_TOO_LONG_REMINDER
  end

  def deny_not_setup_reminder(event)
    event.respond "<@!#{event.user.id}>" + Constants::Speech::DEBY_NOT_SETUP_REMINDER
  end

  def save_reminder_list(reminder_list)
    @reminder_repository.save_all(reminder_list)
  end

  def make_prof(args, event)
    image = MiniMagick::Image.open('src/prof_template.png')
    profile_data = args
    prof_items = [:name, :sex, :adrs]
    ary = [prof_items, profile_data].transpose
    profile_hash = Hash[*ary.flatten]
    profile_hash[:name].to_s.slice!(0..4)
    profile_hash[:sex].to_s.slice!(0..3)
    profile_hash[:adrs].to_s.slice!(0..7)
    profile_img_url = event.user.avatar_url
    profile_img = MiniMagick::Image.open(profile_img_url)
    text_added_image = image.combine_options do |c|
      c.fill '#0f0f0f'
      c.gravity 'northwest'
      c.pointsize 60
      c.annotate '+380+50,0', profile_hash[:name]
      c.annotate '+380+250,0', profile_hash[:sex]
      c.annotate '+70+400,0', profile_hash[:adrs]
    end
    composite_image = text_added_image.composite(profile_img) do |config|
      config.compose 'Over'
      config.gravity 'northwest'
      config.geometry '+50+50'
    end
    composite_image.write 'output.png'
  end
end
