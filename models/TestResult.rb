class TestResult
  include DataMapper::Resource
  property :id, String, key: true
  property :name, String
  property :result, String
  property :warning, String
  property :message, String

  # belongs_to :request_response
  belongs_to :sequence_result
end
