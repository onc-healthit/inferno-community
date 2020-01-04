# frozen_string_literal: true

require File.expand_path '../test_helper.rb', __dir__
class FhirApiTest < MiniTest::Test
  include Rack::Test::Methods

  def app
    Inferno::App.new
  end

  def test_metadata
    get '/fhir/metadata'
    assert last_response.header['Content-Type'].include? 'application/fhir+json'
    includes = ['TestScript', 'TestReport']
    verify_resource(last_response, 'CapabilityStatement', includes)
  end

  # OperationDefinition tests
  def test_operation_definition
    get '/fhir/OperationDefinition'
    verify_bundle(last_response, 'OperationDefinition', 1)

    operation_bundle = FHIR.from_contents(last_response.body)
    operation_id = operation_bundle.entry[0].resource.id
    operation_id_resource(operation_id)
    operation_id_not_found
  end

  def operation_id_resource(operation_id)
    get "/fhir/OperationDefinition/#{operation_id}"
    verify_resource(last_response, 'OperationDefinition')
  end

  def operation_id_not_found
    get '/fhir/OperationDefinition/XXX'
    verify_resource(last_response, 'OperationOutcome')
  end

  # StructureDefinition tests
  def test_structure_definition
    get '/fhir/StructureDefinition'
    verify_bundle(last_response, 'StructureDefinition', 3)

    structure_bundle = FHIR.from_contents(last_response.body)
    structure_id = structure_bundle.entry[0].resource.id

    structure_id_resource(structure_id)
    structure_id_not_found
  end

  def structure_id_resource(structure_id)
    get "/fhir/StructureDefinition/#{structure_id}"
    verify_resource(last_response, 'StructureDefinition')
  end

  def structure_id_not_found
    get '/fhir/StructureDefinition/XXX'
    verify_resource(last_response, 'OperationOutcome')
  end

  # SearchParameter tests
  def test_search_parameter
    get '/fhir/SearchParameter'
    verify_bundle(last_response, 'SearchParameter', 3)

    search_bundle = FHIR.from_contents(last_response.body)
    search_id = search_bundle.entry[0].resource.id

    search_param_id_resource(search_id)
    search_param_id_not_found
  end

  def search_param_id_resource(search_id)
    get "/fhir/SearchParameter/#{search_id}"
    verify_resource(last_response, 'SearchParameter')
  end

  def search_param_id_not_found
    get '/fhir/SearchParameter/XXX'
    verify_resource(last_response, 'OperationOutcome')
  end

  # TestScript tests
  def test_testscript
    get '/fhir/TestScript'
    verify_bundle(last_response, 'TestScript')
    testscript_bundle = FHIR.from_contents(last_response.body)
    testscript_id = testscript_bundle.entry[0].resource.id

    testscript_by_id_bundle(testscript_id)
    testscript_id_not_found_bundle
    testscript_by_id_resource(testscript_id)
    testscript_id_not_found_resource

    testscript_by_module
    testscript_by_module_not_found
  end

  def testscript_by_id_bundle(testscript_id)
    get "/fhir/TestScript?_id=#{testscript_id}"
    verify_bundle(last_response, 'TestScript', 1)
  end

  def testscript_id_not_found_bundle
    get '/fhir/TestScript?_id=XXX'
    verify_bundle(last_response, 'OperationOutcome', 0)
  end

  def testscript_by_id_resource(testscript_id)
    get "/fhir/TestScript/#{testscript_id}"
    verify_resource(last_response, 'TestScript')
  end

  def testscript_id_not_found_resource
    get '/fhir/TestScript/XXX'
    verify_resource(last_response, 'OperationOutcome')
  end

  def testscript_by_module
    get '/fhir/TestScript?module=onc'
    verify_bundle(last_response, 'TestScript')
  end

  def testscript_by_module_not_found
    get '/fhir/TestScript?module=XXX'
    verify_bundle(last_response, 'OperationOutcome')
  end

  # Execution tests
  def test_execute_and_testreports
    testreport_id = execute
    execute_fail
    testreport_by_id_bundle(testreport_id)
    testreport_by_id_not_found_bundle
    test_instance = testreport_by_id_resource(testreport_id)
    testreport_by_id_not_found_resource
    testreport_by_test_instance_found(test_instance)
    testreport_by_test_instance_not_found
  end

  def execute
    # Execute on new instance through url params
    post '/fhir/TestScript/ManualRegistrationSequence/$execute?fhir_server=https://fhir.sitenv.org/secure/fhir&module=onc&client_id=Yg0o6sJ8I8CfVVyHz1eA0m8jv6sXwe&client_secret'
    testreport = FHIR.from_contents(last_response.body)
    testreport_id = testreport.id
    test_instance = testreport.extension[0]&.valueId
    verify_resource(last_response, 'TestReport', ['pass']) # Check for setup operation

    # Execute on new instance through JSON body
    url = '/fhir/TestScript/ManualRegistrationSequence/$execute'
    post(url, execute_params_new_instance.to_json, 'CONTENT_TYPE' => 'application/json')
    verify_resource(last_response, 'TestReport', ['pass'])

    # Execute on old instance through url params (Note: a different test can't be performed because all other tests use http requests)
    post "/fhir/TestScript/ManualRegistrationSequence/$execute?test_instance=#{test_instance}"
    verify_resource(last_response, 'TestReport', ['skip'])

    # Execute on old instance through JSON body (Note: a different test can't be performed because all other tests use http requests)
    url = '/fhir/TestScript/ManualRegistrationSequence/$execute'
    post(url, execute_params_old_instance(test_instance).to_json, 'CONTENT_TYPE' => 'application/json')
    verify_resource(last_response, 'TestReport', ['skip'])

    testreport_id
  end

  def execute_fail
    post 'http://localhost:4567/fhir/TestScript/ManualRegistrationSequence/$execute?fhir_server=https://fhir.sitenv.org/secure/fhir'
    assert(last_response.not_found?)
  end

  # TestReport tests
  def test_testreport
    get '/fhir/TestReport'
    verify_bundle(last_response, 'TestReport')
  end

  def testreport_by_id_bundle(testreport_id)
    get "/fhir/TestReport?_id=#{testreport_id}"
    verify_bundle(last_response, 'TestReport', 1)
  end

  def testreport_by_id_not_found_bundle
    get '/fhir/TestReport?_id=XXX'
    verify_bundle(last_response, 'OperationOutcome', 0)
  end

  def testreport_by_id_resource(testreport_id)
    get "/fhir/TestReport/#{testreport_id}"
    verify_resource(last_response, 'TestReport')
    testreport = FHIR.from_contents(last_response.body)
    testreport.extension[0].valueId
  end

  def testreport_by_id_not_found_resource
    get '/fhir/TestReport/XXX'
    verify_resource(last_response, 'OperationOutcome')
  end

  def testreport_by_test_instance_found(test_instance)
    get "/fhir/TestReport?test_instance=#{test_instance}"
    verify_bundle(last_response, 'TestReport')
  end

  def testreport_by_test_instance_not_found
    get '/fhir/TestReport?test_instance=XXX'
    verify_bundle(last_response, 'OperationOutcome', 0)
  end

  # Helper functions
  def verify_bundle(last_response, resource_class, total_entries = nil)
    assert last_response.ok?
    bundle = FHIR.from_contents(last_response.body)

    assert bundle.valid?, 'validation errors: ' + bundle.validate.inspect
    assert bundle.class == FHIR::Bundle
    assert bundle.total == total_entries unless total_entries.nil?

    bundle.entry.each do |entry|
      assert entry.resource.valid?
      assert entry.resource.class.inspect == "FHIR::#{resource_class}"
    end
  end

  def verify_resource(last_response, resource_class, includes = [])
    assert last_response.ok?, 'last response: ' + last_response.inspect
    resource = FHIR.from_contents(last_response.body)

    includes.each { |contains| assert last_response.body.include? contains }
    assert resource.valid?, 'validation errors: ' + resource.validate.inspect
    assert resource.class.inspect == "FHIR::#{resource_class}"
  end

  def execute_params_new_instance
    {
      "parameter": [
        {
          "name": 'fhir_server',
          "valueUri": 'https://fhir.sitenv.org/secure/fhir'
        },
        {
          "name": 'module',
          "valueString": 'onc'
        },
        {
          "name": 'client_id',
          "valueId": 'Yg0o6sJ8I8CfVVyHz1eA0m8jv6sXwe'
        },
        {
          "name": 'client_secret',
          "valueString": 'UDVrTXlna0NvcGRQZ1VhMkZaZzQ0R1FxVGdtTWxFMXVoT3pPd1VRMUN4MFVkV25Gejk='
        }
      ],
      "resourceType": 'Parameters'
    }
  end

  def execute_params_old_instance(test_instance)
    {
      "parameter": [
        {
          "name": 'test_instance',
          "valueId": test_instance
        }
      ],
      "resourceType": 'Parameters'
    }
  end
end
