class TestResult
  include DataMapper::Resource
  property :id, String, key: true, default: proc { SecureRandom.uuid}
  property :name, String
  property :result, String
  property :message, String, length: 500

  property :url, String, length: 500
  property :description, Text
  property :test_index, Integer
  property :created_at, DateTime, default: proc { DateTime.now }

  property :wait_at_endpoint, String
  property :redirect_to_url, String

  has n, :request_responses, :through => Resource 
  has n, :test_warnings
  belongs_to :sequence_result
end
