require './util/api_util'

require 'yaml'

class DiceRepository < Component
  private

  def construct(bot)
    @trpg_systems = get_trpg_systems
  end

  public

  attr_reader :trpg_systems

  def roll(roll_text, trpg_system = :DiceBot)
    attempt_call_bcdice("/v2/game_system/#{trpg_system}/roll?" + URI.encode_www_form(command: roll_text))['text']
  end

  def choice(choices)
    command = "choice[#{choices.join(',')}]"
    attempt_call_bcdice("/v2/game_system/DiceBot/roll?" + URI.encode_www_form(command: command))['text']
  end

  private

  def get_trpg_systems
    parsed_response = attempt_call_bcdice('/v2/game_system')
    return if parsed_response['game_system'].nil?

    parsed_response['game_system'].map do |system|
      system['id']
    end
  end

  def attempt_call_bcdice(endpoint)
    servers = YAML.safe_load(ApiUtil.get_raw(Constants::URLs::BC_DICE_SERVERS), permitted_classes: [Symbol, Time])
    servers.each do |server|
      begin
        return ApiUtil.get(server + endpoint)
      rescue StandardError
        next
      end
    end
  end
end
