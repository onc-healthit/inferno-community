# frozen_string_literal: true

require_relative '../utils/result_statuses'

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

      has n, :request_responses, through: Resource
      has n, :test_warnings
      belongs_to :sequence_result
    end
  end
end
