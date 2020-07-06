# frozen_string_literal: true

require_relative '../../../../test/test_helper'

describe Inferno::Sequence::SharedLaunchTests do
  class SharedLaunchTestSequence < Inferno::Sequence::SequenceBase
    include Inferno::Sequence::SharedLaunchTests

    auth_endpoint_tls_test(index: '01')
    token_endpoint_tls_test(index: '02')
    code_and_state_received_test(index: '03')
    invalid_code_test(index: '04')
    invalid_client_id_test(index: '05')
    successful_token_exchange_test(index: '06')
    token_response_contents_test(index: '07')
    token_response_headers_test(index: '08')
  end

  before do
    @sequence_class = SharedLaunchTestSequence
    @client = FHIR::Client.new('http://www.example.com/fhir')
    @instance = Inferno::Models::TestingInstance.new
  end

  describe 'auth_endpoint_tls_test' do
    before do
      @test = @sequence_class[:auth_endpoint_tls]
      @sequence = @sequence_class.new(@instance, @client)
    end

    it 'fails when the auth endpoint does not support tls' do
      auth_endpoint = 'http://www.example.com/auth'
      @instance.oauth_authorize_endpoint = auth_endpoint

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal "URI is not HTTPS: #{auth_endpoint}", exception.message
    end

    it 'succeeds when TLS 1.2 is supported' do
      auth_endpoint = 'https://www.example.com/auth'
      @instance.oauth_authorize_endpoint = auth_endpoint

      stub_request(:get, auth_endpoint)
        .to_return(status: 200).then
        .to_raise(StandardError)

      @sequence.run_test(@test)
    end
  end

  describe 'token_endpoint_tls_test' do
    before do
      @test = @sequence_class[:token_endpoint_tls]
      @sequence = @sequence_class.new(@instance, @client)
    end

    it 'fails when the token endpoint does not support tls' do
      token_endpoint = 'http://www.example.com/token'
      @instance.oauth_token_endpoint = token_endpoint

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal "URI is not HTTPS: #{token_endpoint}", exception.message
    end

    it 'succeeds when TLS 1.2 is supported' do
      token_endpoint = 'https://www.example.com/token'
      @instance.oauth_token_endpoint = token_endpoint

      stub_request(:get, token_endpoint)
        .to_return(status: 200).then
        .to_raise(StandardError)

      @sequence.run_test(@test)
    end
  end

  describe 'code_and_state_received_test' do
    before do
      @test = @sequence_class[:code_and_state_received]
      @sequence = @sequence_class.new(@instance, @client)
      @sequence.instance_variable_set(:@params, 'abc' => 'def')
      @instance.state = 'STATE'
    end

    it 'skips if the received params are blank' do
      @sequence.instance_variable_set(:@params, {})

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal @sequence.oauth_redirect_failed_message, exception.message
    end

    it 'fails if an error is received' do
      @sequence.instance_variable_set(:@params, 'error' => 'ERROR MESSAGE')

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal @sequence.auth_server_error_message, exception.message
    end

    it 'fails if an invalid state is received' do
      @sequence.instance_variable_set(:@params, 'state' => 'INCORRECT STATE')

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal @sequence.bad_state_error_message, exception.message
    end

    it 'fails if no code is received' do
      @sequence.instance_variable_set(:@params, 'state' => 'STATE')

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected code to be submitted in request', exception.message
    end

    it 'succeeds if a code and the correct state are received' do
      @sequence.instance_variable_set(:@params, 'state' => 'STATE', 'code' => 'ABC')

      @sequence.run_test(@test)
    end
  end

  describe 'invalid_code_test' do
    before do
      @test = @sequence_class[:invalid_code]
      @sequence = @sequence_class.new(@instance, @client)
      @instance.redirect_uris = 'http://www.example.com/redirect'
      @instance.client_id = 'CLIENT_ID'
      @instance.oauth_token_endpoint = 'http://www.example.com/token'
      @token_headers = { 'Content-Type' => 'application/x-www-form-urlencoded' }
      @token_params = {
        grant_type: 'authorization_code',
        code: 'INVALID_CODE',
        redirect_uri: @instance.redirect_uris
      }
    end

    it 'skips if the received params are blank' do
      @sequence.instance_variable_set(:@params, {})

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal @sequence.oauth_redirect_failed_message, exception.message
    end

    describe 'with public client' do
      before do
        @token_params[:client_id] = @instance.client_id
        @instance.confidential_client = false
        @sequence.instance_variable_set(:@params, 'code' => 'CODE')
      end

      it 'fails if a successful response is received' do
        stub_request(:post, @instance.oauth_token_endpoint)
          .with(body: @token_params, headers: @token_headers)
          .to_return(status: 200)

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal 'Bad response code: expected 400, but found 200', exception.message
      end

      it 'succeeds if a 400 response is received' do
        stub_request(:post, @instance.oauth_token_endpoint)
          .with(body: @token_params, headers: @token_headers)
          .to_return(status: 400)

        @sequence.run_test(@test)
      end
    end

    describe 'with a confidential client' do
      before do
        @instance.confidential_client = true
        @instance.client_secret = 'CLIENT_SECRET'
        client_credentials = "#{@instance.client_id}:#{@instance.client_secret}"
        @token_headers['Authorization'] = "Basic #{Base64.strict_encode64(client_credentials)}"
        @sequence.instance_variable_set(:@params, 'code' => 'CODE')
      end

      it 'fails if a successful response is received' do
        stub_request(:post, @instance.oauth_token_endpoint)
          .with(body: @token_params, headers: @token_headers)
          .to_return(status: 200)

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal 'Bad response code: expected 400, but found 200', exception.message
      end

      it 'succeeds if a 400 response is received' do
        stub_request(:post, @instance.oauth_token_endpoint)
          .with(body: @token_params, headers: @token_headers)
          .to_return(status: 400)

        @sequence.run_test(@test)
      end
    end
  end

  describe 'invalid_client_id_test' do
    before do
      @test = @sequence_class[:invalid_client_id]
      @sequence = @sequence_class.new(@instance, @client)
      @sequence.instance_variable_set(:@params, 'code' => 'CODE')
      @instance.redirect_uris = 'http://www.example.com/redirect'
      @instance.client_id = 'CLIENT_ID'
      @instance.oauth_token_endpoint = 'http://www.example.com/token'
      @token_headers = { 'Content-Type' => 'application/x-www-form-urlencoded' }
      @token_params = {
        grant_type: 'authorization_code',
        code: 'CODE',
        redirect_uri: @instance.redirect_uris
      }
    end

    it 'skips if the received params are blank' do
      @sequence.instance_variable_set(:@params, {})

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal @sequence.oauth_redirect_failed_message, exception.message
    end

    describe 'with public client' do
      before do
        @token_params[:client_id] = 'INVALID_CLIENT_ID'
        @instance.confidential_client = false
      end

      it 'fails if a successful response is received' do
        stub_request(:post, @instance.oauth_token_endpoint)
          .with(body: @token_params, headers: @token_headers)
          .to_return(status: 200)

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal 'Bad response code: expected 400 or 401, but found 200', exception.message
      end

      it 'succeeds if a 400 response is received' do
        stub_request(:post, @instance.oauth_token_endpoint)
          .with(body: @token_params, headers: @token_headers)
          .to_return(status: 400)

        @sequence.run_test(@test)
      end
    end

    describe 'with a confidential client' do
      before do
        @instance.confidential_client = true
        @instance.client_secret = 'CLIENT_SECRET'
        client_credentials = "INVALID_CLIENT_ID:#{@instance.client_secret}"
        @token_headers['Authorization'] = "Basic #{Base64.strict_encode64(client_credentials)}"
      end

      it 'fails if a successful response is received' do
        stub_request(:post, @instance.oauth_token_endpoint)
          .with(body: @token_params, headers: @token_headers)
          .to_return(status: 200)

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal 'Bad response code: expected 400 or 401, but found 200', exception.message
      end

      it 'succeeds if a 400 response is received' do
        stub_request(:post, @instance.oauth_token_endpoint)
          .with(body: @token_params, headers: @token_headers)
          .to_return(status: 400)

        @sequence.run_test(@test)
      end
    end
  end

  describe 'successful_token_exchange_test' do
    before do
      @test = @sequence_class[:successful_token_exchange]
      @sequence = @sequence_class.new(@instance, @client)
      @sequence.instance_variable_set(:@params, 'code' => 'CODE')
      @instance.redirect_uris = 'http://www.example.com/redirect'
      @instance.client_id = 'CLIENT_ID'
      @instance.oauth_token_endpoint = 'http://www.example.com/token'
      @token_headers = { 'Content-Type' => 'application/x-www-form-urlencoded' }
      @token_params = {
        grant_type: 'authorization_code',
        code: 'CODE',
        redirect_uri: @instance.redirect_uris
      }
    end

    it 'skips if the received params are blank' do
      @sequence.instance_variable_set(:@params, {})

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal @sequence.oauth_redirect_failed_message, exception.message
    end

    describe 'with public client' do
      before do
        @token_params[:client_id] = @instance.client_id
        @instance.confidential_client = false
      end

      it 'fails if a non-successful response is received' do
        stub_request(:post, @instance.oauth_token_endpoint)
          .with(body: @token_params, headers: @token_headers)
          .to_return(status: 400)

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal 'Bad response code: expected 200, 201, but found 400. ', exception.message
      end

      it 'succeeds if a 200 response is received' do
        stub_request(:post, @instance.oauth_token_endpoint)
          .with(body: @token_params, headers: @token_headers)
          .to_return(status: 200)

        @sequence.run_test(@test)
      end
    end

    describe 'with a confidential client' do
      before do
        @instance.confidential_client = true
        @instance.client_secret = 'CLIENT_SECRET'
        client_credentials = "#{@instance.client_id}:#{@instance.client_secret}"
        @token_headers['Authorization'] = "Basic #{Base64.strict_encode64(client_credentials)}"
      end

      it 'fails if a non-successful response is received' do
        stub_request(:post, @instance.oauth_token_endpoint)
          .with(body: @token_params, headers: @token_headers)
          .to_return(status: 400)

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal 'Bad response code: expected 200, 201, but found 400. ', exception.message
      end

      it 'succeeds if a 200 response is received' do
        stub_request(:post, @instance.oauth_token_endpoint)
          .with(body: @token_params, headers: @token_headers)
          .to_return(status: 200)

        @sequence.run_test(@test)
      end
    end
  end

  describe 'token_response_contents_test' do
    before do
      @test = @sequence_class[:token_response_contents]
      @sequence = @sequence_class.new(@instance, @client)
      @sequence.instance_variable_set(:@params, 'abc' => 'def')
    end

    it 'skips if the launch failed' do
      @sequence.instance_variable_set(:@params, {})

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal @sequence.oauth_redirect_failed_message, exception.message
    end

    it 'skips if the token response is blank' do
      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal @sequence.no_token_response_message, exception.message
    end

    it 'fails if the token response does not contain an access token' do
      response = {}
      @sequence.instance_variable_set(:@token_response, OpenStruct.new(body: response.to_json))
      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Token response did not contain access_token as required', exception.message
    end

    it 'fails if the token response does not contain the token_type' do
      response = { access_token: 'ABC' }
      @sequence.instance_variable_set(:@token_response, OpenStruct.new(body: response.to_json))
      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Token response did not contain token_type as required', exception.message
    end

    it 'fails if the token response does not contain the scope' do
      response = { access_token: 'ABC', token_type: 'DEF' }
      @sequence.instance_variable_set(:@token_response, OpenStruct.new(body: response.to_json))
      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Token response did not contain scope as required', exception.message
    end

    it 'fails if the token response contains unrequestesd scopes' do
      @instance.scopes = 'DEF'
      response = {
        access_token: 'ABC',
        token_type: 'Bearer',
        scope: @instance.scopes + ' GHI'
      }

      @sequence.instance_variable_set(:@token_response, OpenStruct.new(body: response.to_json))
      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Token response contained unrequested scopes: GHI', exception.message
    end

    it 'fails if the token_type is not "bearer"' do
      response = {
        access_token: 'ABC',
        token_type: 'DEF',
        scope: 'GHI'
      }
      @sequence.instance_variable_set(:@token_response, OpenStruct.new(body: response.to_json))
      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Token type must be Bearer.', exception.message
    end

    it 'generates a warning if the response contains a non-numeric value for expires_in' do
      @instance.scopes = 'GHI'
      response = {
        access_token: 'ABC',
        token_type: 'Bearer',
        scope: 'GHI',
        expires_in: 'DEF'
      }
      @sequence.instance_variable_set(:@token_response, OpenStruct.new(body: response.to_json))
      @sequence.run_test(@test)

      warnings = @sequence.instance_variable_get(:@test_warnings)
      assert warnings.include?('`expires_in` field is not a number: "DEF"')
    end

    it 'generates a warning if no expires_in provided but still successfully saves patient id' do
      @instance.scopes = 'GHI'
      response = {
        access_token: 'ABC',
        token_type: 'Bearer',
        scope: 'GHI',
        patient: '5'
      }
      @sequence.instance_variable_set(:@token_response, OpenStruct.new(body: response.to_json))
      @sequence.run_test(@test)

      warnings = @sequence.instance_variable_get(:@test_warnings)
      assert warnings.include?('Token exchange response did not contain the recommended `expires_in` field')
      assert @instance.patient_id == '5', 'patient_id not saved when expires_in empty'
    end

    it 'succeeds if the token_type is "bearer" and an access token and scope are included' do
      @instance.scopes = 'GHI'
      response = {
        access_token: 'ABC',
        token_type: 'Bearer',
        scope: 'GHI',
        expires_in: 300
      }
      @sequence.instance_variable_set(:@token_response, OpenStruct.new(body: response.to_json))

      @sequence.run_test(@test)
    end
  end

  describe 'token_response_headers_test' do
    before do
      @test = @sequence_class[:token_response_headers]
      @sequence = @sequence_class.new(@instance, @client)
      @sequence.instance_variable_set(:@params, 'abc' => 'def')
    end

    it 'skips if the launch failed' do
      @sequence.instance_variable_set(:@params, {})

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal @sequence.oauth_redirect_failed_message, exception.message
    end

    it 'skips if the token response is blank' do
      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal @sequence.no_token_response_message, exception.message
    end

    it 'fails if the token response contains no cache_control header' do
      headers = {}
      @sequence.instance_variable_set(:@token_response, OpenStruct.new(headers: headers))

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Token response headers did not contain cache_control as is required in the SMART App Launch Guide.', exception.message
    end

    it 'fails if the token response contains no pragma header' do
      headers = { cache_control: 'ABC' }
      @sequence.instance_variable_set(:@token_response, OpenStruct.new(headers: headers))

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Token response headers did not contain pragma as is required in the SMART App Launch Guide.', exception.message
    end

    it 'fails if the cache_control header does not include "no-store"' do
      headers = { cache_control: 'ABC', pragma: 'DEF' }
      @sequence.instance_variable_set(:@token_response, OpenStruct.new(headers: headers))

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Token response header must have cache_control containing no-store.', exception.message
    end

    it 'fails if the pragma header does not include "no-cache"' do
      headers = { cache_control: 'no-store', pragma: 'DEF' }
      @sequence.instance_variable_set(:@token_response, OpenStruct.new(headers: headers))

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Token response header must have pragma containing no-cache.', exception.message
    end

    it 'succeeds if the cache_control and pragma headers contain the correct values' do
      headers = { cache_control: 'no-store', pragma: 'no-cache' }
      @sequence.instance_variable_set(:@token_response, OpenStruct.new(headers: headers))

      @sequence.run_test(@test)
    end
  end
end
