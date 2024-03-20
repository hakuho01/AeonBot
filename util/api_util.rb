# frozen_string_literal: true

require 'net/http'
require 'open-uri'

# API通信
module ApiUtil
  def get(api_uri, headers = {})
    uri = URI.parse(api_uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == "https")
  
    request = Net::HTTP::Get.new(uri)
    headers.each { |key, value| request[key] = value }

    response = http.request(request)
    JSON.parse(response.body)
  end

  def post(api_uri, body, headers = {})
    uri = URI.parse(api_uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == "https")

    request = Net::HTTP::Post.new(uri.request_uri)
    request.body = body.to_json
    headers.each { |key, value| request[key] = value }

    response = http.request(request)
    JSON.parse(response.body)
  end

  module_function :get, :post
end
