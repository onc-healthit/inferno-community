class SequenceResult
  include DataMapper::Resource
  property :id, String, key: true
  property :name, String
  property :result, String #pass fail
  property :created_at, DateTime, default: proc { DateTime.now }

  property :redirect_to_url, String
  property :wait_at_endpoint, String

  property :passed_count, Integer, default: 0
  property :failed_count, Integer, default: 0
  property :error_count, Integer, default: 0
  property :warning_count, Integer, default: 0
  property :todo_count, Integer, default: 0

  has n, :test_results, order: [:created_at.asc]
  belongs_to :testing_instance
end
