# frozen_string_literal: true

require File.expand_path '../test_helper.rb', __dir__
require 'eventmachine'

class OAuth2EndpointsTest < MiniTest::Test
  include Rack::Test::Methods
  include Inferno::App::Helpers::BrowserLogic

  def base_path
    '/inferno'
  end

  def app
    Inferno::App.new
  end

  def create_testing_instance(params = {})
    default_params = {
      url: 'http://example.com',
      client_endpoint_key: 'static',
      selected_module: 'smart',
      initiate_login_uri: '/login'
    }

    Inferno::Models::TestingInstance.create(default_params.merge(params))
  end

  def create_sequence_result(params = {})
    default_params = {
      result: 'wait',
      test_set_id: 'developer',
      test_case_id: 'developer_SMARTonFHIRTesting_EHRLaunchSequence',
      next_test_cases: ''
    }

    Inferno::Models::SequenceResult.create(default_params.merge(params))
  end

  def setup
    WebMock.disable_net_connect!
  end

  def test_launch_response_success
    instance = create_testing_instance
    sequence_result = create_sequence_result(
      testing_instance: instance,
      wait_at_endpoint: 'launch',
      redirect_to_url: '/redirect'
    )
    Inferno::Models::TestResult.create(
      sequence_result: sequence_result
    )

    EventMachine.run do
      get '/inferno/oauth2/static/launch?iss=http://example.com'

      assert last_response.ok?

      redirect_path = "#{Inferno::BASE_PATH}/#{instance.id}/test_sets/#{sequence_result.test_set_id}/#SMARTonFHIRTesting/#{sequence_result.test_case_id}"
      assert last_response.body.include? js_redirect(redirect_path)
      break
    end
  end

  def test_redirect_response_success
    instance = create_testing_instance(state: 'abc123')
    sequence_result = create_sequence_result(
      testing_instance: instance,
      wait_at_endpoint: 'redirect'
    )
    Inferno::Models::TestResult.create(
      sequence_result: sequence_result
    )

    EventMachine.run do
      get '/inferno/oauth2/static/redirect?state=abc123'

      assert last_response.ok?

      redirect_path = "#{Inferno::BASE_PATH}/#{instance.id}/test_sets/#{sequence_result.test_set_id}/#SMARTonFHIRTesting/#{sequence_result.test_case_id}"
      assert last_response.body.include? js_redirect(redirect_path)
      break
    end
  end

  def test_404_page
    get '/asdfasdf'
    assert last_response.not_found?
  end
end
