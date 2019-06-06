# frozen_string_literal: true

module Inferno
  module Models
    class SequenceResult
      include DataMapper::Resource
      property :id, String, key: true, default: proc { SecureRandom.uuid }
      property :name, String
      property :result, String
      property :test_case_id, String
      property :test_set_id, String

      property :redirect_to_url, String, length: 500
      property :wait_at_endpoint, String

      property :required_passed, Integer, default: 0
      property :required_total, Integer, default: 0
      property :error_count, Integer, default: 0
      property :todo_count, Integer, default: 0
      property :skip_count, Integer, default: 0
      property :optional_passed, Integer, default: 0
      property :optional_total, Integer, default: 0

      property :app_version, String

      property :required, Boolean, default: true
      property :input_params, String
      property :output_results, String

      property :next_sequences, String
      property :next_test_cases, String

      property :created_at, DateTime, default: proc { DateTime.now }

      has n, :test_results, order: [:test_index.asc]
      belongs_to :testing_instance

      def fail?
        result == 'fail' || error?
      end

      def error?
        result == 'error'
      end

      def pass?
        result == 'pass'
      end

      def skip?
        result == 'skip'
      end

      def wait?
        result == 'wait'
      end

      def failures
        test_results.select(&:fail?)
      end

      def reset!
        [
          'required_passed',
          'required_total',
          'error_count',
          'skip_count',
          'optional_passed',
          'optional_total'
        ].each { |field| send("#{field}=", 0) }
      end
    end
  end
end
