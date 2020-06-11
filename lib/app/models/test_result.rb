# frozen_string_literal: true

require_relative '../utils/result_statuses'
require_relative 'information_message'

module Inferno
  module Models
    class TestResult
      include ResultStatuses
      include DataMapper::Resource
      property :id, String, key: true, default: proc { SecureRandom.uuid }
      property :test_id, String
      property :ref, String
      property :name, String
      property :result, String
      property :message, String, length: 500
      property :details, String
      property :required, Boolean, default: true

      property :url, String, length: 500
      property :description, Text
      property :test_index, Integer
      property :created_at, DateTime, default: proc { DateTime.now }
      property :versions, String

      property :wait_at_endpoint, String
      property :redirect_to_url, String
      property :expect_redirect_failure, Boolean, default: false

      has n, :request_responses, through: Resource, order: [:timestamp.asc]
      has n, :test_warnings
      has n, :information_messages
      belongs_to :sequence_result
    end
  end
end
