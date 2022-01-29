require './func/methods'

class DiceRepository
  def initialize
    @trpg_systems = []
  end

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
    parsed_response = attempt_call_bcdice('/v2/game_system/game_system')
    parsed_response['game_system'].map do |system|
      system['id']
    end
  end

  def attempt_call_bcdice(endpoint)
    begin
      get_api(Constants::URLs::BC_DICE + endpoint)
    rescue
      get_api(Constants::URLs::BC_DICE_BACKUP + endpoint)
    end
  end
end
