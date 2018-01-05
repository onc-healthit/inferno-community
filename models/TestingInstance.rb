class TestingInstance
  include DataMapper::Resource
  property :id, String, key: true
  property :url, String
  property :name, String
  property :client_id, String
  property :scopes, String

  property :conformance_checked, Boolean
  property :oauth_authorize_endpoint, String
  property :oauth_token_endpoint, String
  property :fhir_format, String
  property :client_id, String

  property :dynamically_registered, Boolean
  property :client_endpoint_key, String, default: proc { SecureRandomBase62.generate(32) }

  property :created_at, DateTime, default: proc { DateTime.now }

  has n, :sequence_results
end
