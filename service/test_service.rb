# frozen_string_literal: true

require 'pg'

Dotenv.load
DB_HOST = ENV['DB_HOST']
DB_USER = ENV['DB_USER']
DB_PASS = ENV['DB_PASS']
DB_NAME = ENV['DB_NAME']

class TestService < Component
  def testing(event, args)
    # ここにテストしたい処理を書く
    puts event
    puts args
    db_connection = PG::Connection.new(host: DB_HOST, port: 5432, dbname: DB_NAME, user: DB_USER, password: DB_PASS)
    puts db_connection
    db_connection
  end
end
