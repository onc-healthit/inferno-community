class TestResult
  include DataMapper::Resource
  property :id, String, key: true
  property :name, String
  property :result, String
  property :warning, String
  property :message, String

  property :url, String, length: 500
  property :description, Text

  has n, :request_responses, :through => Resource 
  belongs_to :sequence_result
end
