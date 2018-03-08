class TestingInstance
  include DataMapper::Resource
  property :id, String, key: true, default: proc { SecureRandomBase62.generate(32) }
  property :url, String
  property :name, String
  property :client_id, String
  property :base_url, String

  property :client_name, String
  property :scopes, String
  property :launch_type, String
  property :state, String

  property :conformance_checked, Boolean
  property :oauth_authorize_endpoint, String
  property :oauth_token_endpoint, String
  property :oauth_register_endpoint, String
  property :fhir_format, String

  property :dynamically_registered, Boolean
  property :client_endpoint_key, String, default: proc { SecureRandomBase62.generate(32) }

  property :token, String
  property :token_retrieved_at, DateTime

  property :created_at, DateTime, default: proc { DateTime.now }
  
  property :oauth_introspection_endpoint, String
  property :resource_id, String
  property :resource_secret, String
  property :introspect_token, String

  has n, :sequence_results
  has n, :supported_resources, order: [:index.asc]
  has n, :resource_references

  def latest_results
    self.sequence_results.reduce({}) do |hash, result| 
      if hash[result.name].nil? || hash[result.name].created_at < result.created_at
        hash[result.name] = result 
      end
      hash
    end
  end

  def waiting_on_sequence
    self.sequence_results.first(result: 'wait')
  end

  def final_result

    required_sequences = SequenceBase.subclasses.reject(&:optional?)

    all_passed = required_sequences.all? do |sequence|
      self.latest_results[sequence.name].try(:result) == 'pass'
    end

    if all_passed
      return 'pass'
    else
      return 'fail'
    end

  end

  def patient_id
    self.resource_references.select{|ref| ref.resource_type == 'patient'}.first.try(:resource_id)
  end

end
