require './framework/repository'

class PlaneChaserRepository < Repository
  def select_plane(plane_num)
    @db['SELECT * FROM planes WHERE id = ?', plane_num].first
  end
end
