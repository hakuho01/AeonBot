# frozen_string_literal: true

require 'net/http'
require 'open-uri'

# API通信
module ApiUtil
  def get_raw(api_uri, headers = {})
    uri = URI.parse(api_uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == "https")

    request = Net::HTTP::Get.new(uri)
    headers.each { |key, value| request[key] = value }

    response = http.request(request)
    raise ApiError, "Error: #{response.code} - #{response.message}" unless response.code == '200'

    response.body
  end

  def get(api_uri, headers = {})
    response_body = get_raw(api_uri, headers)
    JSON.parse(response_body)
  end

  def post(api_uri, body, headers = {})
    uri = URI.parse(api_uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == "https")

    request = Net::HTTP::Post.new(uri.request_uri)
    request.body = body.to_json
    headers.each { |key, value| request[key] = value }

    response = http.request(request)
    raise "Error: #{response.code} - #{response.message}" unless response.code == '200'

    JSON.parse(response.body)
  end

  module_function :get, :post, :get_raw

end

# API通信の例外クラス
class ApiError < StandardError
end
