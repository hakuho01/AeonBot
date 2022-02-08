# frozen_string_literal: true

require 'net/http'
require 'open-uri'

# API通信
def get_api(api_uri)
  uri = URI.parse(api_uri)
  response = Net::HTTP.get_response(uri)
  JSON.parse(response.body)
end
