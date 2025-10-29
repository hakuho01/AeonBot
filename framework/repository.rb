require 'pg'
require 'sequel'

Dotenv.load
DB_HOST = ENV['DB_HOST']
DB_USER = ENV['DB_USER']
DB_PASS = ENV['DB_PASS']
DB_NAME = ENV['DB_NAME']
SCHEMA_ENV = ENV['SCHEMA_ENV']

class Repository < Component
  def initialize
    @db = Sequel.postgres(
      DB_NAME,
      user: DB_USER,
      password: DB_PASS,
      host: DB_HOST,
      port: 5432,
      sslmode: 'require',
      connect_timeout: 10
    )
    @db.run("set search_path to #{SCHEMA_ENV}")
  end
end
