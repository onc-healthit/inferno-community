# frozen_string_literal: true

require File.expand_path '../test_helper.rb', __dir__
class ApiTest < MiniTest::Test
  include Rack::Test::Methods

  PREFIX = '/api/v1/'

  def app
    Inferno::App.new
  end

  # Tests test_set endpoints
  def test_test_set
    get "#{PREFIX}test_set"
    verify_group(last_response, 'test_set')
    test_set_id = JSON.parse(last_response.body)[0]['id']

    get "#{PREFIX}test_set/#{test_set_id}"
    verify_resource(last_response, 'test_set')

    get "#{PREFIX}test_set/XXX"
    verify_resource(last_response, 'error')
  end

  # Tests preset endpoints
  # Unable to fully test presets because presets are filtered by base url, so presets in test environment are empty
  def test_preset
    get "#{PREFIX}preset"
    #   verify_group(last_response, 'preset')
    #   preset_id = JSON.parse(last_response.body)[0]['id']

    #   get "#{PREFIX}preset/#{preset_id}"
    #   verify_resource(last_response, 'preset')

    #   get "#{PREFIX}preset/XXX"
    #   verify_resource(last_response, 'error')

    #   Create instance from preset
    #   body = { "preset": preset_id }
    #   post("#{PREFIX}instance", body.to_json, 'CONTENT_TYPE' => 'application/json')
    #   verify_resource(last_response, 'instance')
  end

  # Tests general instance endpoints
  def test_instance
    body = {
      "fhir_server": 'https://fhir.sitenv.org/secure/fhir',
      "test_set": 'onc',
      "client_id": 'Yg0o6sJ8I8CfVVyHz1eA0m8jv6sXwe',
      "client_secret": 'UDVrTXlna0NvcGRQZ1VhMkZaZzQ0R1FxVGdtTWxFMXVoT3pPd1VRMUN4MFVkV25Gejk='
    }
    post("#{PREFIX}instance", body.to_json, 'CONTENT_TYPE' => 'application/json')
    verify_resource(last_response, 'instance')
    instance_id = JSON.parse(last_response.body)['id']

    get "#{PREFIX}instance/#{instance_id}"
    verify_resource(last_response, 'instance')

    get "#{PREFIX}instance/XXX"
    verify_resource(last_response, 'error')

    module_test(instance_id)
    group_id = group_test(instance_id)
    sequence_test(instance_id, group_id)
  end

  # Execute tests
  # Can only test using Manual Registration Sequence because all other tests have http connections that aren't allowed
  # Therefore, no testing for: executing on groups, getting requests
  # No testing for execute_stream because can't handle a stream
  def test_execute
    body = {
      "fhir_server": 'https://fhir.sitenv.org/secure/fhir',
      "test_set": 'argonaut',
      "client_id": 'Yg0o6sJ8I8CfVVyHz1eA0m8jv6sXwe',
      "client_secret": 'UDVrTXlna0NvcGRQZ1VhMkZaZzQ0R1FxVGdtTWxFMXVoT3pPd1VRMUN4MFVkV25Gejk='
    }
    post("#{PREFIX}instance", body.to_json, 'CONTENT_TYPE' => 'application/json')
    verify_resource(last_response, 'instance')

    instance_id = JSON.parse(last_response.body)['id']
    group_id = 'AuthorizationandAuthentication'
    sequence_id = 'ManualRegistrationSequence'

    # Execute sequence
    post "#{PREFIX}instance/#{instance_id}/module/group/#{group_id}/sequence/#{sequence_id}/$execute"
    verify_resource(last_response, 'result')

    result_test(instance_id, group_id, sequence_id)
    report_test(instance_id)

    # Can't test request_test because no requests are performed in the tests executed, see above note
    # result_id = result_test(instance_id, group_id, sequence_id)
    # request_test(instance_id, result_id)

    # Execute sequence with stream: performs no tests because format is ndjson, not json
    post "#{PREFIX}instance/#{instance_id}/module/group/#{group_id}/sequence/#{sequence_id}/$execute_stream"
  end

  # Tests module endpoint
  def module_test(instance_id)
    get "#{PREFIX}instance/#{instance_id}/module"
    verify_resource(last_response, 'module')
  end

  # Tests module/group endpoints
  def group_test(instance_id)
    get "#{PREFIX}instance/#{instance_id}/module/group"
    verify_group(last_response, 'group')
    group_id = JSON.parse(last_response.body)[0]['id']

    get "#{PREFIX}instance/#{instance_id}/module/group/#{group_id}"
    verify_resource(last_response, 'group')

    get "#{PREFIX}instance/#{instance_id}/module/group/XXX"
    verify_resource(last_response, 'error')

    group_id
  end

  # Tests module/group/sequence endpoints
  def sequence_test(instance_id, group_id)
    get "#{PREFIX}instance/#{instance_id}/module/group/#{group_id}/sequence"
    verify_group(last_response, 'sequence')
    sequence_id = JSON.parse(last_response.body)[0]['id']

    get "#{PREFIX}instance/#{instance_id}/module/group/#{group_id}/sequence/#{sequence_id}"
    verify_resource(last_response, 'sequence')

    get "#{PREFIX}instance/#{instance_id}/module/group/#{group_id}/sequence/XXX"
    verify_resource(last_response, 'error')

    sequence_id
  end

  # Tests result endpoints
  def result_test(instance_id, group_id, sequence_id)
    get "#{PREFIX}instance/#{instance_id}/result"
    verify_group(last_response, 'result')

    result_id = JSON.parse(last_response.body)[0]['id']

    get "#{PREFIX}instance/#{instance_id}/result/#{result_id}"
    verify_resource(last_response, 'result')

    get "#{PREFIX}instance/#{instance_id}/result/group/#{group_id}"
    verify_group(last_response, 'result')

    get "#{PREFIX}instance/#{instance_id}/result/group/#{group_id}/sequence/#{sequence_id}"
    verify_resource(last_response, 'result')

    get "#{PREFIX}instance/#{instance_id}/result/XXX"
    verify_resource(last_response, 'error')

    result_id
  end

  # Tests request endpoints
  # This function is never called, see notes above
  def request_test(instance_id, result_id)
    get "#{PREFIX}instance/#{instance_id}/result/#{result_id}/request"
    verify_group(last_response, 'request')
    request_id = JSON.parse(last_response.body)[0]['id']

    get "#{PREFIX}instance/#{instance_id}/result/#{result_id}/request/#{request_id}"
    verify_resource(last_response, 'request')

    get "#{PREFIX}instance/#{instance_id}/result/#{result_id}/request/XXX"
    verify_resource(last_response, 'error')
  end

  # Tests report endpoints
  def report_test(instance_id)
    get "#{PREFIX}instance/#{instance_id}/report"
    verify_resource(last_response, 'report')
  end

  # Helper functions
  def verify_resource(last_response, type)
    assert(last_response.ok?, 'last response: ' + last_response.body.inspect) unless type == 'error'
    resource = JSON.parse(last_response.body)
    assert resource['type'] == type
  end

  def verify_group(last_response, type, total_resources = nil)
    assert last_response.ok?, 'last response: ' + last_response.body.inspect
    resources = JSON.parse(last_response.body)
    assert resources.length == total_resources unless total_resources.nil?
    resources.each { |resource| assert resource['type'] == type }
  end
end
