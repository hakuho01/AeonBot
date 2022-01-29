# frozen_string_literal: true

require 'singleton'
require 'discordrb'
require 'dotenv'
require 'json'
require 'mini_magick'

require './framework/component'
require './config/constants'
require './func/methods'
require './util/time_util'
require './repository/reminder_repository'
require './repository/dice_repository'
require './model/reminder'

Dotenv.load
SERVER_ID = ENV['SERVER_ID'].to_i
ISOLATE_ROLE_ID = ENV['ISOLATE_ROLE_ID'].to_i
DEPRIVATE_ROLE_ID = ENV['DEPRIVATE_ROLE_ID'].to_i
IS_TEST_MODE = ENV['IS_TEST_MODE'] == 'true'
WELCOME_CHANNEL_ID = ENV['WELCOME_CHANNEL_ID']
PROFILENOTE_CHANNEL_ID = ENV['PROFILENOTE_CHANNEL_ID']

class BotService < Component
  private

  def construct(bot)
    @reminder_repository = ReminderRepository.instance.init(bot)
    @dice_repository = DiceRepository.instance.init(bot)
    @bot = bot
  end

  public

  def say_good_morning(event)
    event.respond "<@!#{event.user.id}>" << 'おはよう。'
  end

  def say_good_night(event)
    event.respond "<@!#{event.user.id}>" << 'おやすみ。'
  end

  def suggest_rakuten(event)
    rakuten event
  end

  def suggest_wikipedia(event)
    wikipedia event
  end

  def challenge_gacha(event)
    emojis = event.server.emoji.to_a
    results = []
    10.times do
      results.push(emojis.sample)
    end
    gacha_result = []
    results.each do |n|
      gacha_result.push(n[1])
    end
    event.respond gacha_result.join
  end

  def roll_dice(args, event)
    if @dice_repository.trpg_systems.include? args.last
      trpg_system = args.pop
      event.respond "<@!#{event.user.id}>" << @dice_repository.roll(args.join(" "), trpg_system)
    elsif
      event.respond "<@!#{event.user.id}>" << @dice_repository.roll(args.join(" "))
    end
  end

  def random_choice(args, event)
    event.respond "<@!#{event.user.id}>" << @dice_repository.choice(args)
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

  def make_prof(args, event)
    image = MiniMagick::Image.open('resources/img/prof_template.png')
    profile_data = args
    prof_items = [:name, :inviter, :birthday, :comic, :anime, :game, :social_game, :food, :music, :free_space]
    ary = [prof_items, profile_data].transpose
    profile_hash = Hash[*ary.flatten]
    profile_hash[:name].to_s.slice!(0..2)
    profile_hash[:inviter].to_s.slice!(0..3)
    profile_hash[:birthday].to_s.slice!(0..3)
    profile_hash[:comic].to_s.slice!(0..6)
    profile_hash[:anime].to_s.slice!(0..6)
    profile_hash[:game].to_s.slice!(0..6)
    profile_hash[:social_game].to_s.slice!(0..7)
    profile_hash[:food].to_s.slice!(0..6)
    profile_hash[:music].to_s.slice!(0..5)
    profile_hash[:free_space].to_s.slice!(0..4)
    user_name = event.user.display_name
    created_time = event.user.creation_time
    profile_img_url = event.user.avatar_url
    profile_img = MiniMagick::Image.open(profile_img_url)
    text_added_image = image.combine_options do |c|
      c.fill '#0f0f0f'
      c.gravity 'northwest'
      c.font 'resources/font/kiloji_p.ttf'
      c.pointsize 34
      c.annotate '+570+131,0', user_name
      c.annotate '+322+191,0', profile_hash[:name]
      c.annotate '+322+251,0', profile_hash[:inviter]
      c.annotate '+540+313,0', profile_hash[:birthday]
      c.annotate '+324+375,0', created_time.strftime('%Y年%m月%d日')
      c.annotate '+220+530,0', profile_hash[:comic]
      c.annotate '+220+600,0', profile_hash[:anime]
      c.annotate '+220+666,0', profile_hash[:game]
      c.annotate '+693+530,0', profile_hash[:social_game]
      c.annotate '+693+600,0', profile_hash[:food]
      c.annotate '+693+666,0', profile_hash[:music]
      c.annotate '+95+800,0', profile_hash[:free_space]
    end
    edited_profile_img = profile_img.resize '190x190'
    composite_image = text_added_image.composite(edited_profile_img) do |config|
      config.compose 'Over'
      config.gravity 'northwest'
      config.geometry '+100+145'
    end
    Dir.mkdir('./output/') unless Dir.exist?('./output/')
    prof_img_path = './output/prof.png'
    composite_image.write prof_img_path
    @bot.send_file(WELCOME_CHANNEL_ID, File.open(prof_img_path))
    @bot.send_file(PROFILENOTE_CHANNEL_ID, File.open(prof_img_path))
  end
end
