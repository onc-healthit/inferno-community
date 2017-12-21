class TestingInstance
  include DataMapper::Resource
  property :id, String, key: true
  property :url, String
  property :name, String
  property :oauth_authorize_endpoint, String
  property :oauth_token_endpoint, String
  property :fhir_format, String
  property :client_endpoint_key, String, :default => SecureRandom.uuid.split("-").first
  property :dynamically_registered, Boolean
  property :created_at, DateTime

  has n, :sequence_results
end
