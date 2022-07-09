# frozen_string_literal: true

require 'pg'
require 'sequel'

Dotenv.load
DB_HOST = ENV['DB_HOST']
DB_USER = ENV['DB_USER']
DB_PASS = ENV['DB_PASS']
DB_NAME = ENV['DB_NAME']
SCHEMA_ENV = ENV['SCHEMA_ENV']

class PlaneChaserService < Component
  def planes(args, event)
    plane_num = args[0].to_i
    db = Sequel.postgres(DB_NAME, user: DB_USER, password: DB_PASS, host: DB_HOST)
    plane = db["SELECT * FROM #{SCHEMA_ENV}.planes"].to_a.find{ |hash| hash[:id] == plane_num }
    event.send_embed do |embed|
      embed.title = plane[:name]
      embed.description = plane[:effect]
    end
  end
end
