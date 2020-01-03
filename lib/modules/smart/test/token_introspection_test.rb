# frozen_string_literal: true

require_relative '../../../../test/test_helper'

class TokenIntrospectionSequenceTest < MiniTest::Test
  REQUEST_HEADERS = { 'Accept' => 'application/json', 'Content-type' => 'application/x-www-form-urlencoded' }.freeze

  def setup
    introspect_token = 'INTROSPECT_TOKEN'
    introspect_refresh_token = 'INTROSPECT_REFRESH_TOKEN'
    resource_id = SecureRandom.uuid
    resource_secret = SecureRandom.hex(32)

    @instance = Inferno::Models::TestingInstance.create(
      url: 'http://www.example.com',
      client_name: 'Inferno',
      base_url: 'http://localhost:4567',
      received_scopes: 'launch openid patient/*.* profile',
      oauth_introspection_endpoint: 'https://oauth_reg.example.com/introspect',
      introspect_token: introspect_token,
      selected_module: 'argonaut',
      introspect_refresh_token: introspect_refresh_token,
      resource_id: resource_id,
      resource_secret: resource_secret,
      token_retrieved_at: DateTime.now
    )

    client = FHIR::Client.new(@instance.url)
    client.use_dstu2
    client.default_json

    @sequence = Inferno::Sequence::TokenIntrospectionSequence.new(@instance, client, true)
  end

  def test_all_pass
    WebMock.reset!
    params = {
      'token' => @instance.introspect_token,
      'client_id' => @instance.resource_id,
      'client_secret' => @instance.resource_secret
    }
    response = {
      'active' => true,
      'scope' => @instance.received_scopes,
      'exp' => 2.hours.from_now.to_i
    }
    refresh_params = {
      'token' => @instance.introspect_refresh_token,
      'client_id' => @instance.resource_id,
      'client_secret' => @instance.resource_secret
    }
    refresh_response = {
      'active' => true
    }

    stub_register = stub_request(:post, @instance.oauth_introspection_endpoint)
      .with(headers: REQUEST_HEADERS, body: params)
      .to_return(status: 200, body: response.to_json)

    stub_refresh_register = stub_request(:post, @instance.oauth_introspection_endpoint)
      .with(headers: REQUEST_HEADERS, body: refresh_params)
      .to_return(status: 200, body: refresh_response.to_json)

    sequence_result = @sequence.start

    assert_requested(stub_register)
    assert_requested(stub_refresh_register)

    failures = sequence_result.failures

    assert failures.empty?, "All tests should pass.  First error: #{!failures.empty? && failures.first.message}"
    assert sequence_result.pass?, 'Sequence should pass.'
    assert sequence_result.test_results.all? { |r| r.test_warnings.empty? }, 'There should not be any warnings.'
  end

  def test_no_introspection_endpoint
    WebMock.reset!
    params = {
      'token' => @instance.introspect_token,
      'client_id' => @instance.resource_id,
      'client_secret' => @instance.resource_secret
    }
    refresh_params = {
      'token' => @instance.introspect_refresh_token,
      'client_id' => @instance.resource_id,
      'client_secret' => @instance.resource_secret
    }

    stub_register = stub_request(:post, @instance.oauth_introspection_endpoint)
      .with(headers: REQUEST_HEADERS, body: params)
      .to_return(status: 404)

    stub_refresh_register = stub_request(:post, @instance.oauth_introspection_endpoint)
      .with(headers: REQUEST_HEADERS, body: refresh_params)
      .to_return(status: 404)

    sequence_result = @sequence.start

    assert_requested(stub_register)
    assert_requested(stub_refresh_register)

    assert sequence_result.fail?, 'Sequence should fail.'
    assert sequence_result.test_results.select(&:pass?).empty?, 'No tests should pass (the tls testing sequence).'
  end

  def test_inactive
    WebMock.reset!
    params = {
      'token' => @instance.introspect_token,
      'client_id' => @instance.resource_id,
      'client_secret' => @instance.resource_secret
    }
    response = {
      'active' => false,
      'scope' => @instance.received_scopes,
      'exp' => 2.hours.from_now.to_i
    }
    refresh_params = {
      'token' => @instance.introspect_refresh_token,
      'client_id' => @instance.resource_id,
      'client_secret' => @instance.resource_secret
    }
    refresh_response = {
      'active' => true
    }

    stub_register = stub_request(:post, @instance.oauth_introspection_endpoint)
      .with(headers: REQUEST_HEADERS, body: params)
      .to_return(status: 200, body: response.to_json)
    stub_refresh_register = stub_request(:post, @instance.oauth_introspection_endpoint)
      .with(headers: REQUEST_HEADERS, body: refresh_params)
      .to_return(status: 200, body: refresh_response.to_json)

    sequence_result = @sequence.start

    assert_requested(stub_register)
    assert_requested(stub_refresh_register)

    failures = sequence_result.failures

    # 1 test depends on active being true
    assert failures.length == 1, 'One test should fail.'
    assert sequence_result.fail?, 'Sequence should fail.'
  end

  def test_refresh_inactive
    WebMock.reset!
    params = {
      'token' => @instance.introspect_token,
      'client_id' => @instance.resource_id,
      'client_secret' => @instance.resource_secret
    }
    response = {
      'active' => true,
      'scope' => @instance.received_scopes,
      'exp' => 2.hours.from_now.to_i
    }
    refresh_params = {
      'token' => @instance.introspect_refresh_token,
      'client_id' => @instance.resource_id,
      'client_secret' => @instance.resource_secret
    }
    refresh_response = {
      'active' => false
    }

    stub_register = stub_request(:post, @instance.oauth_introspection_endpoint)
      .with(headers: REQUEST_HEADERS, body: params)
      .to_return(status: 200, body: response.to_json)
    stub_refresh_register = stub_request(:post, @instance.oauth_introspection_endpoint)
      .with(headers: REQUEST_HEADERS, body: refresh_params)
      .to_return(status: 200, body: refresh_response.to_json)

    sequence_result = @sequence.start

    assert_requested(stub_register)
    assert_requested(stub_refresh_register)

    failures = sequence_result.failures

    # 1 optional test depends on active being true
    assert failures.length == 1 && !failures.first.required, 'One optional test should fail.'
    # This should still pass because the one failing test is optional
    assert sequence_result.pass?, 'Sequence should pass.'
  end

  def test_insufficient_scopes
    WebMock.reset!
    params = {
      'token' => @instance.introspect_token,
      'client_id' => @instance.resource_id,
      'client_secret' => @instance.resource_secret
    }
    response = {
      'active' => true,
      'scope' => @instance.received_scopes.split(' ')[0...-1].join(' '), # remove last scope
      'exp' => 2.hours.from_now.to_i
    }
    refresh_params = {
      'token' => @instance.introspect_refresh_token,
      'client_id' => @instance.resource_id,
      'client_secret' => @instance.resource_secret
    }
    refresh_response = {
      'active' => true
    }

    stub_register = stub_request(:post, @instance.oauth_introspection_endpoint)
      .with(headers: REQUEST_HEADERS, body: params)
      .to_return(status: 200, body: response.to_json)
    stub_refresh_register = stub_request(:post, @instance.oauth_introspection_endpoint)
      .with(headers: REQUEST_HEADERS, body: refresh_params)
      .to_return(status: 200, body: refresh_response.to_json)

    sequence_result = @sequence.start

    assert_requested(stub_register)
    assert_requested(stub_refresh_register)

    failures = sequence_result.failures

    # 1 optional test depends on correct scopes
    assert failures.length == 1, 'One test should fail.'
    assert sequence_result.pass?, 'Sequence should pass.'
  end

  def test_additional_scopes
    WebMock.reset!
    params = {
      'token' => @instance.introspect_token,
      'client_id' => @instance.resource_id,
      'client_secret' => @instance.resource_secret
    }
    response = {
      'active' => true,
      'scope' => @instance.received_scopes + ' extra', # add extra scope
      'exp' => 2.hours.from_now.to_i
    }
    refresh_params = {
      'token' => @instance.introspect_refresh_token,
      'client_id' => @instance.resource_id,
      'client_secret' => @instance.resource_secret
    }
    refresh_response = {
      'active' => true
    }

    stub_register = stub_request(:post, @instance.oauth_introspection_endpoint)
      .with(headers: REQUEST_HEADERS, body: params)
      .to_return(status: 200, body: response.to_json)
    stub_refresh_register = stub_request(:post, @instance.oauth_introspection_endpoint)
      .with(headers: REQUEST_HEADERS, body: refresh_params)
      .to_return(status: 200, body: refresh_response.to_json)

    sequence_result = @sequence.start

    assert_requested(stub_register)
    assert_requested(stub_refresh_register)

    failures = sequence_result.failures

    # 1 optional test depends on correct scopes
    assert failures.length == 1, 'One test should fail.'
    assert sequence_result.pass?, 'Sequence should pass.'
  end

  def test_expiration
    WebMock.reset!
    params = {
      'token' => @instance.introspect_token,
      'client_id' => @instance.resource_id,
      'client_secret' => @instance.resource_secret
    }
    response = {
      'active' => false,
      'scope' => @instance.received_scopes,
      'exp' => 30.minutes.from_now.to_i # should be at least 60 minutes
    }
    refresh_params = {
      'token' => @instance.introspect_refresh_token,
      'client_id' => @instance.resource_id,
      'client_secret' => @instance.resource_secret
    }
    refresh_response = {
      'active' => true
    }

    stub_register = stub_request(:post, @instance.oauth_introspection_endpoint)
      .with(headers: REQUEST_HEADERS, body: params)
      .to_return(status: 200, body: response.to_json)
    stub_refresh_register = stub_request(:post, @instance.oauth_introspection_endpoint)
      .with(headers: REQUEST_HEADERS, body: refresh_params)
      .to_return(status: 200, body: refresh_response.to_json)

    sequence_result = @sequence.start

    assert_requested(stub_register)
    assert_requested(stub_refresh_register)

    failures = sequence_result.failures

    # 1 test depends on expiration being at least 60 minutes
    assert failures.length == 1, 'One test should fail.'
    assert sequence_result.fail?, 'Sequence should fail.'
  end
end
