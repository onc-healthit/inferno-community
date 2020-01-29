# frozen_string_literal: true

require File.expand_path '../test_helper.rb', __dir__
class TerminologyEndpointTest < MiniTest::Test
  include Rack::Test::Methods

  def setup
    # Load a minimal set of validators
    # Note: these could already be loaded through sequence_base
    Inferno::Terminology.load_validators('test/fixtures/validators')
  end

  def app
    Inferno::App.new
  end

  def test_capability_statement
    get '/fhir/metadata'
    assert last_response.ok?, 'Operation should return a 200 status code'
    assert_equal 'application/fhir+json', last_response.content_type
    assert FHIR.from_contents(last_response.body), "Couldn't deserialize CapabilityStatement into a FHIR::Models object"
  end

  def test_terminology_capability_statement
    get '/fhir/metadata?mode=terminology'
    assert last_response.ok?, 'Operation should return a 200 status code'
    assert_equal 'application/fhir+json', last_response.content_type
    refute_empty FHIR.from_contents(last_response.body).codeSystem
  end

  def test_valueset_validates_good_code
    post '/fhir/ValueSet/$validate-code', load_fixture('valueset_validates_code_params_good'), 'CONTENT_TYPE' => 'application/fhir+json'
    assert last_response.ok?, 'Operation should return a 200 status code'
    assert FHIR.from_contents(last_response.body).parameter.find { |p| p.name == 'result' }&.value
  end

  def test_valueset_validates_bad_code
    post '/fhir/ValueSet/$validate-code', load_fixture('valueset_validates_code_params_bad'), 'CONTENT_TYPE' => 'application/fhir+json'
    assert last_response.ok?, 'Operation should return a 200 status code'
    refute FHIR.from_contents(last_response.body).parameter.find { |p| p.name == 'result' }&.value
  end

  def test_codesystem_validates_good_code
    post '/fhir/CodeSystem/$validate-code', load_fixture('codesystem_validates_code_params_good'), 'CONTENT_TYPE' => 'application/fhir+json'
    assert last_response.ok?, 'Operation should return a 200 status code'
    assert FHIR.from_contents(last_response.body).parameter.find { |p| p.name == 'result' }&.value
  end

  def test_codesystem_validates_bad_code
    post '/fhir/CodeSystem/$validate-code', load_fixture('codesystem_validates_code_params_bad'), 'CONTENT_TYPE' => 'application/fhir+json'
    assert last_response.ok?, 'Operation should return a 200 status code'
    refute FHIR.from_contents(last_response.body).parameter.find { |p| p.name == 'result' }&.value
  end

  def test_valueset_validates_good_codeableconcept
    post 'fhir/ValueSet/$validate-code', load_fixture('valueset_validates_codeableconcept_params_good'), 'CONTENT_TYPE' => 'application/fhir+json'
    assert last_response.ok?, 'Operation should return a 200 status code'
    assert FHIR.from_contents(last_response.body).parameter.find { |p| p.name == 'result' }&.value
  end

  def test_valueset_validates_bad_codeableconcept
    post 'fhir/ValueSet/$validate-code', load_fixture('valueset_validates_codeableconcept_params_bad'), 'CONTENT_TYPE' => 'application/fhir+json'
    assert last_response.ok?, 'Operation should return a 200 status code'
    refute FHIR.from_contents(last_response.body).parameter.find { |p| p.name == 'result' }&.value
  end
end
