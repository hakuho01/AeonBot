require './framework/repository'

class FavstarRepository < Repository
  def check_faved_message(message_id)
    @db['SELECT * FROM "favs" WHERE message_id = ?', message_id]
  end

  def add_faved_message(message_id)
    @db[:favs].insert(message_id: message_id)
  end
end
