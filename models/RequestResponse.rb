class RequestResponse
  include DataMapper::Resource
  property :id, String, key: true
  property :request_method, String
  property :request_url, String
  property :request_headers, String
  property :request_body, String
  property :response_code, Integer
  property :response_headers, String
  property :response_body, String

  # has n, :test_result
end
