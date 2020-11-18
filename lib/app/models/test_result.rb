# frozen_string_literal: true

require_relative '../utils/result_statuses'
require_relative 'information_message'

module Inferno
  class TestResult < ApplicationRecord
    include ResultStatuses

    attribute :id, :string, default: -> { SecureRandom.uuid }
    attribute :required, :boolean, default: true
    attribute :created_at, :datetime, default: -> { DateTime.now }
    attribute :test_id, :string

    has_and_belongs_to_many :request_responses, -> { order 'timestamp ASC' },
                            join_table: :inferno_models_request_response_test_results
    has_many :test_warnings
    has_many :information_messages
    belongs_to :sequence_result
  end
end
