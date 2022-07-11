# frozen_string_literal: true

require 'dotenv'
require './framework/component'

Dotenv.load
FAVSTAR_CH_ID = ENV['FAVSTAR_CH_ID']
KUSA_ID = ENV['KUSA_ID']

class FavstarService < Component
  private

  def construct(bot)
    @bot = bot
  end

  public

  def memory_fav(event)
    favstar_ch_id = FAVSTAR_CH_ID

    kusas = event.message.reactions.find { |n| n.id == KUSA_ID.to_i }.count
    return if kusas != 10

    @bot.send_message(favstar_ch_id, "**#{event.message.author.display_name}**\n#{event.message.content}\nhttps://discord.com/channels/#{event.server.id}/#{event.channel.id}/#{event.message.id}")
  end
end
