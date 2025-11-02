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
    # Heroku Postgres: DATABASE_URL を使用
    @db = Sequel.connect(
      ENV['DATABASE_URL'],
      sslmode: 'require',
      connect_timeout: 10
    )
    @db.run("set search_path to #{SCHEMA_ENV}")
  end
end
