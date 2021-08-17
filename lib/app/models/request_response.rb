# frozen_string_literal: true

module Inferno
  class RequestResponse < ApplicationRecord
    attribute :id, :string, default: -> { SecureRandom.uuid }
    attribute :timestamp, :datetime, default: -> { DateTime.now }

    has_and_belongs_to_many :test_results, join_table: :inferno_models_request_response_test_results
    belongs_to :instance, class_name: 'TestingInstance'

    def self.from_request(req, instance_id, direction = nil)
      request = req.request
      response = req.response

      response_body = response[:body]
      response_body = '' if response_body.nil?
      escaped_body = response_body.dup
      unescape_unicode(escaped_body)

      new(
        direction: direction || req&.direction,
        request_method: request[:method],
        request_url: request[:url],
        request_headers: stringify_headers(request[:headers]),
        request_payload: request[:payload],
        response_code: response[:code],
        response_headers: stringify_headers(response[:headers]),
        response_body: escaped_body,
        instance_id: instance_id,
        timestamp: response[:timestamp]
      )
    end

    def self.stringify_headers(headers)
      headers.to_json
    rescue StandardError => e
      { 'ERROR' => "#{e.class}: #{e.message}" }.to_json
    end

    # This is needed to escape HTML when the html tags are unicode escape sequences
    # https://stackoverflow.com/questions/7015778/is-this-the-best-way-to-unescape-unicode-escape-sequences-in-ruby
    def self.unescape_unicode(body)
      body.gsub!(/\\u(\h{4})/) { |_m| [Regexp.last_match(1)].pack('H*').unpack('n*').pack('U*') }
    end
  end
end
