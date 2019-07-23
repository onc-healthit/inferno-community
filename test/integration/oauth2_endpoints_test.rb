# frozen_string_literal: true

require File.expand_path '../test_helper.rb', __dir__
require 'eventmachine'

class HomePageTest < MiniTest::Test
  include Rack::Test::Methods
  include Inferno::App::Helpers::BrowserLogic

  def base_path
    '/inferno'
  end

  def app
    Inferno::App.new
  end

  def setup
    WebMock.disable_net_connect!
    # stub_request(:any, 'http://example.com/')
  end

  def test_launch_response_success
    instance = Inferno::Models::TestingInstance.new(
      url: 'http://example.com',
      client_endpoint_key: 'static',
      selected_module: 'smart',
      initiate_login_uri: '/launch'
    )
    instance.save
    sr = Inferno::Models::SequenceResult.new(
      result: 'wait',
      testing_instance: instance,
      test_set_id: 'developer',
      test_case_id: 'developer_SMARTonFHIRTesting_EHRLaunchSequence',
      wait_at_endpoint: 'launch',
      next_test_cases: '',
      redirect_to_url: '/redirect'
    )
    sr.save
    tr = Inferno::Models::TestResult.new(
      sequence_result: sr
    )
    tr.save

    EventMachine.run do
      get '/inferno/oauth2/static/launch?iss=http://example.com'
      assert last_response.ok?
      assert last_response.body.include? js_redirect("#{Inferno::BASE_PATH}/#{instance.id}/test_sets/#{sr.test_set_id}/#SMARTonFHIRTesting/#{sr.test_case_id}")
      break
    end
  end

  def test_404_page
    get '/asdfasdf'
    assert last_response.not_found?
  end
end
