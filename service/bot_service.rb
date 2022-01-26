require 'singleton'
require 'discordrb'
require 'dotenv'
require 'json'

require './config/constants'
require './func/methods'
require './util/time_util'
require './repository/reminder_repository'

Dotenv.load
SERVER_ID = ENV['SERVER_ID'].to_i
ISOLATE_ROLE_ID = ENV['ISOLATE_ROLE_ID'].to_i
DEPRIVATE_ROLE_ID = ENV['DEPRIVATE_ROLE_ID'].to_i
IS_TEST_MODE = ENV['IS_TEST_MODE'] == 'true'

class BotService
  def initialize(bot)
    @reminder_repository = ReminderRepository.new(bot)
    @bot = bot
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
    server = @bot.server(SERVER_ID)
    member = server.member(event.user.id)
    if member.roles.include?(ISOLATE_ROLE_ID)
      event.respond Constants::Speech::PURGE
      if IS_TEST_MODE
        event.respond Constants::Speech::PURGE_TEST_MODE
      else
        server.kick(event.user.id)
      end
    else
      member.add_role(ISOLATE_ROLE_ID)
      member.remove_role(DEPRIVATE_ROLE_ID)
    end
  end

  def remind(reminder)
    message = "<@!#{reminder.user_id}>" + Constants::Speech::REMIND % reminder.message
    @bot.channel(reminder.channel_id).send_message(message)
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
    event.respond "<@!#{event.user.id}>" + Constants::Speech::DENY_NOT_SETUP_REMINDER
  end

  def save_reminder_list(reminder_list)
    @reminder_repository.save_all(reminder_list)
  end
end