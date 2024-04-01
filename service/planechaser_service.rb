# frozen_string_literal: true

require './repository/planechaser_repository'

class PlaneChaserService < Component
  def construct
    @planechaser_repository = PlaneChaserRepository.instance.init
  end

  def planes(args, event)
    plane = @planechaser_repository.select_plane(args[0].to_i)
    event.send_embed do |embed|
      embed.title = plane[:name]
      embed.description = plane[:effect].gsub('\n', "\n")
    end
  end
end
