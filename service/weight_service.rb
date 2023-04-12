# frozen_string_literal: true

require 'dotenv'
require './framework/component'
require './repository/weight_repository'

Dotenv.load
WEIGHT_CH_ID = ENV['WEIGHT_CH_ID']

class WeightService < Component
  private

  def construct
    @weight_repository = WeightRepository.instance.init
  end

  public

  def archive_weight(event)
    return if event.channel.id.to_s != WEIGHT_CH_ID # やせましょう・ふとりましょうチャンネル以外では反応しない

    weight = event.content.to_f # 体重をfloat型で取得
    user_id = event.user.id
    date = Time.now
    @weight_repository.add_weight(user_id, date, weight)
  end

  def draw_graph(event)
    return if event.channel.id.to_s != WEIGHT_CH_ID # やせましょう・ふとりましょうチャンネル以外では反応しない

    user_id = event.user.id
    weight_datasets = @weight_repository.get_weights(user_id)
    puts weight_datasets

  end
end
