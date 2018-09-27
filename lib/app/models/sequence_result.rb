module Inferno
  module Models
    class SequenceResult
      include DataMapper::Resource
      property :id, String, key: true, default: proc { SecureRandom.uuid}
      property :name, String
      property :result, String

      property :redirect_to_url, String, length: 500
      property :wait_at_endpoint, String

      property :passed_count, Integer, default: 0
      property :failed_count, Integer, default: 0
      property :error_count, Integer, default: 0
      property :todo_count, Integer, default: 0
      property :skip_count, Integer, default: 0

      property :app_version, String

      property :required, Boolean, default: true

      property :next_sequences, String

      property :created_at, DateTime, default: proc { DateTime.now }

      has n, :test_results, order: [:test_index.asc]
      belongs_to :testing_instance

    end
  end
end

