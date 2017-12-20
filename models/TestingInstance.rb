class TestingInstance
  include DataMapper::Resource
  property :id, String, key: true
  property :url, String
  property :name, String
  property :oauth_endpoint, String
  property :fhir_format, String
  property :redirect_key, String
  property :launch_key, String
  property :created_at, DateTime

  has n, :sequence_results
end
