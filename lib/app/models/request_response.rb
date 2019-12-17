# frozen_string_literal: true

module Inferno
  module Models
    class RequestResponse
      include DataMapper::Resource
      property :id, String, key: true, default: proc { SecureRandom.uuid }
      property :request_method, String
      property :request_url, String, length: 500
      property :request_headers, String, length: 1000
      property :request_payload, Text
      property :response_code, Integer
      property :response_headers, String, length: 1000
      property :response_body, Text
      property :direction, String
      property :instance_id, String

      property :response_time, DateTime

      has n, :test_results, through: Resource

      def self.from_request(req, instance_id, direction = nil)
        request = req.request
        response = req.response
        headers = response[:headers]
        new(
          direction: direction || req&.direction,
          request_method: request[:method],
          request_url: request[:url],
          request_headers: request[:headers].to_json,
          request_payload: request[:payload],
          response_code: response[:code],
          response_headers: headers.to_json,
          response_body: response[:body],
          instance_id: instance_id,
          response_time: DateTime.parse(headers['date'] || headers[:date])
        )
      end
    end
  end
end
