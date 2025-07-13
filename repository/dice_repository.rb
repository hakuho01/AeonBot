require './util/api_util'

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
    trpg_systems = []
    parsed_response = attempt_call_bcdice('/v2/game_system')
    puts "parsed_response: #{parsed_response}"
    puts "game_system: #{parsed_response['game_system']}"
    return if parsed_response['game_system'].nil?

    trpg_systems = parsed_response['game_system'].map do |system|
      system['id']
    end
    return trpg_systems
  end

  def attempt_call_bcdice(endpoint)
    begin
      ApiUtil.get(Constants::URLs::BC_DICE + endpoint)
    rescue
      ApiUtil.get(Constants::URLs::BC_DICE_BACKUP + endpoint)
    end
  end
end
