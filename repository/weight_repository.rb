require './framework/repository'

class WeightRepository < Repository
  def check_faved_message(message_id)
    @db['SELECT * FROM favs WHERE message_id = ?', message_id]
  end

  def add_weight(user_id, date, weight)
    @db[:weights].insert(user_id: user_id, date: date, weight: weight)
  end

  def get_weights(user_id)
    @db[:weights].where(user_id: user_id).select(:date, :weight).all
  end
end
