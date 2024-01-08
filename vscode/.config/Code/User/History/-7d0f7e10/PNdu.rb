# frozen_string_literal: true

module Crm
  # Módulo para conexión a HubSpot
  module HubSpot
    HS_API_TOKEN = ENV['HUBSPOT_API_TOKEN']
    def self.update_counter(url:, body: nil, **_extra_args)
      post_to_api(url, body)
    end

    def self.post_to_api(url, body)
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      req = Net::HTTP::Post.new(
        uri,
        'Content-Type'  => 'application/json',
        'Authorization' => "Bearer #{HS_API_TOKEN}"
      )
      req.body = body
      http.request(req)
    end
  end
end
