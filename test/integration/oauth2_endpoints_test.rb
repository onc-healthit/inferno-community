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
    set_global_mocks
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

  def test_launch_response_not_running
    create_testing_instance

    EventMachine.run do
      bad_iss = 'http://example.com/UNKNOWN_ISS'
      get "/inferno/oauth2/static/launch?iss=#{bad_iss}"

      assert last_response.status == 500

      expected_error_message = "Error: No actively running launch sequences found for iss #{bad_iss}"
      assert last_response.body.include? expected_error_message
      break
    end
  end

  def test_launch_response_no_iss
    instance = create_testing_instance(url: 'http://example.com/no_iss')
    sequence_result = create_sequence_result(
      testing_instance: instance,
      wait_at_endpoint: 'launch',
      redirect_to_url: '/redirect'
    )
    Inferno::Models::TestResult.create(
      sequence_result: sequence_result
    )

    EventMachine.run do
      cookies = { 'HTTP_COOKIE' => "instance_id_test_set=#{instance.id}/" }
      get '/inferno/oauth2/static/launch', {}, cookies

      assert last_response.ok?

      redirect_path = "#{Inferno::BASE_PATH}/#{instance.id}/test_sets/#{sequence_result.test_set_id}/#SMARTonFHIRTesting/#{sequence_result.test_case_id}"
      assert last_response.body.include? js_redirect(redirect_path)

      failure_found = sequence_result.test_results.any? do |result|
        result.fail? && result.message == 'No iss querystring parameter provided to launch uri'
      end

      assert failure_found
      break
    end
  end

  def test_launch_response_unknown_iss
    bad_iss = 'http://example.com/UNKNOWN_ISS'
    instance = create_testing_instance(url: 'http://example.com/no_iss')
    sequence_result = create_sequence_result(
      testing_instance: instance,
      wait_at_endpoint: 'launch',
      redirect_to_url: '/redirect'
    )
    Inferno::Models::TestResult.create(
      sequence_result: sequence_result
    )

    EventMachine.run do
      cookies = { 'HTTP_COOKIE' => "instance_id_test_set=#{instance.id}/" }
      get "/inferno/oauth2/static/launch?iss=#{bad_iss}", {}, cookies

      assert last_response.ok?

      redirect_path = "#{Inferno::BASE_PATH}/#{instance.id}/test_sets/#{sequence_result.test_set_id}/#SMARTonFHIRTesting/#{sequence_result.test_case_id}"
      assert last_response.body.include? js_redirect(redirect_path)

      failure_found = sequence_result.test_results.any? do |result|
        result.fail? && result.message == "Unknown iss: #{bad_iss}"
      end

      assert failure_found
      break
    end
  end

  def test_launch_response_not_waiting
    instance = create_testing_instance
    sequence_result = create_sequence_result(
      testing_instance: instance,
      result: 'pass'
    )
    Inferno::Models::TestResult.create(
      sequence_result: sequence_result
    )

    EventMachine.run do
      cookies = { 'HTTP_COOKIE' => "instance_id_test_set=#{instance.id}/" }
      get '/inferno/oauth2/static/launch?iss=http://example.com', {}, cookies

      assert last_response.redirect?
      assert last_response.headers['Location'].include? '?error=no_ehr_launch'
      break
    end
  end

  def test_redirect_response_success
    state = SecureRandom.uuid
    instance = create_testing_instance(state: state)
    sequence_result = create_sequence_result(
      testing_instance: instance,
      wait_at_endpoint: 'redirect'
    )
    Inferno::Models::TestResult.create(
      sequence_result: sequence_result
    )

    EventMachine.run do
      get "/inferno/oauth2/static/redirect?state=#{state}"

      assert last_response.ok?

      redirect_path = "#{Inferno::BASE_PATH}/#{instance.id}/test_sets/#{sequence_result.test_set_id}/#SMARTonFHIRTesting/#{sequence_result.test_case_id}"
      assert last_response.body.include? js_redirect(redirect_path)
      break
    end
  end

  def test_redirect_response_not_running
    create_testing_instance

    EventMachine.run do
      bad_state = 'xyz'
      get "/inferno/oauth2/static/redirect?state=#{bad_state}"

      assert last_response.status == 500

      expected_error_message = "No actively running launch sequences found with a state of #{bad_state}"
      assert last_response.body.include? expected_error_message
      break
    end
  end

  def test_redirect_response_bad_state
    state = SecureRandom.uuid
    instance = create_testing_instance(state: state)
    sequence_result = create_sequence_result(
      testing_instance: instance,
      wait_at_endpoint: 'redirect'
    )
    Inferno::Models::TestResult.create(
      sequence_result: sequence_result
    )

    EventMachine.run do
      cookies = { 'HTTP_COOKIE' => "instance_id_test_set=#{instance.id}/" }
      get "/inferno/oauth2/static/redirect?state=#{state}x", {}, cookies

      assert last_response.ok?

      redirect_path = "#{Inferno::BASE_PATH}/#{instance.id}/test_sets/#{sequence_result.test_set_id}/#SMARTonFHIRTesting/#{sequence_result.test_case_id}"
      assert last_response.body.include? js_redirect(redirect_path)

      failure_found = sequence_result.test_results.any? do |result|
        result.fail? && result.message.start_with?('State provided in redirect')
      end

      assert failure_found
      break
    end
  end

  def test_redirect_response_not_waiting
    state = SecureRandom.uuid
    instance = create_testing_instance(state: state)
    sequence_result = create_sequence_result(
      testing_instance: instance,
      result: 'pass'
    )
    Inferno::Models::TestResult.create(
      sequence_result: sequence_result
    )

    EventMachine.run do
      cookies = { 'HTTP_COOKIE' => "instance_id_test_set=#{instance.id}/" }
      get "/inferno/oauth2/static/redirect?state=#{state}x", {}, cookies

      assert last_response.redirect?
      assert last_response.headers['Location'].include? '?error=no_state'
      break
    end
  end
end
