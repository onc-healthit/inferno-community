class RequestResponse
  include DataMapper::Resource
  property :id, String, key: true, default: proc { SecureRandom.uuid}
  property :request_method, String
  property :request_url, String, length: 500
  property :request_headers, String, length: 1000
  property :request_body, Text
  property :response_code, Integer
  property :response_headers, String, length: 1000
  property :response_body, Text

  has n, :test_results, :through => Resource
end
