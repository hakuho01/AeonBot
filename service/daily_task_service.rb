require './config/constants'
require './util/time_util'

Dotenv.load
FPS_CHANNEL_ID = ENV['FPS_CHANNEL_ID'].to_i
WARN_FPS_PLAYERS_CHANNEL_ID = ENV['WARN_FPS_PLAYERS_CHANNEL_ID'].to_i

class DailyTaskSerivice
  def initialize(bot)
    @bot = bot
    @last_warned_time = Time.at(0)
  end

  attr_reader :last_warned_time

  def get_fps_players
    @bot.channel(FPS_CHANNEL_ID).users
  end

  def warn_fps_players(fps_players)
    mentions = fps_players.map do |fps_player|
      "<@!#{fps_player.id}>"
    end
    @bot.channel(WARN_FPS_PLAYERS_CHANNEL_ID).send_message(mentions.join(" ") + Constants::Speech::WARN_FPS_PLAYERS.sample)
    @last_warned_time = TimeUtil.now
  end
end
