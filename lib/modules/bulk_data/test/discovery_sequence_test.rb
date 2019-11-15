# frozen_string_literal: true

require_relative '../../../../test/test_helper'

describe Inferno::Sequence::BulkDataDiscoverySequence do
  before do
    @sequence_class = Inferno::Sequence::BulkDataDiscoverySequence

    @instance = Inferno::Models::TestingInstance.create(
      url: 'http://www.example.com'
    )

    @client = FHIR::Client.new(@instance.url)

    @well_known_endpoint = @instance.url + '/.well-known/smart-configuration'
    @conformance_endpoint = @instance.url + '/metadata'

    @smart_configuration = {
      'token_endpoint' => 'https://www.example.com/auth/token',
      'token_endpoint_auth_methods_supported' => ['private_key_jwt'],
      'token_endpoint_auth_signing_alg_values_supported' => ['RS384', 'ES384'],
      'scopes_supported' => ['system/*.read'],
      'registration_endpoint' => 'https://www.example.com/auth/register'
    }

    @conformance = load_json_fixture(:bulk_data_conformance)
  end

  describe 'read well known endpoints tests' do
    before do
      @test = @sequence_class[:read_well_known_endpoint]
      @sequence = @sequence_class.new(@instance, @client)
    end

    it 'succeeds when server returns smart configuration' do
      stub_request(:get, @well_known_endpoint)
        .to_return(
          status: 200,
          headers: { content_type: 'application/json' },
          body: @smart_configuration.to_json
        )

      @sequence.run_test(@test)
      assert @instance.oauth_token_endpoint == @smart_configuration['token_endpoint']
      assert @instance.oauth_register_endpoint == @smart_configuration['registration_endpoint']
    end

    it 'fails when server returns 400' do
      stub_request(:get, @well_known_endpoint)
        .to_return(
          status: 400
        )

      assert_raises(Inferno::AssertionException) do
        @sequence.run_test(@test)
      end
    end

    it 'fails when response header is not application/json' do
      stub_request(:get, @well_known_endpoint)
        .to_return(
          status: 200,
          headers: { content_type: 'application/text' }
        )

      assert_raises(Inferno::AssertionException) do
        @sequence.run_test(@test)
      end
    end

    it 'fails when response body is not JSON object' do
      stub_request(:get, @well_known_endpoint)
        .to_return(
          status: 200,
          headers: { content_type: 'application/json' },
          body: 'This is a string'
        )

      assert_raises(Inferno::AssertionException) do
        @sequence.run_test(@test)
      end
    end
  end

  describe 'well-known configuration test' do
    before do
      @test = @sequence_class[:validate_well_known_configuration]
      @sequence = @sequence_class.new(@instance, @client)
      @sequence.well_known_configuration = @smart_configuration.clone
    end

    it 'succeeds when well-known configuration is valid' do
      @sequence.run_test(@test)
    end

    it 'fails when well-known configuration does not have required fields' do
      @sequence.well_known_configuration.delete('token_endpoint')

      assert_raises(Inferno::AssertionException) do
        @sequence.run_test(@test)
      end
    end

    it 'skips when well-known configuration is empty' do
      @sequence.well_known_configuration = nil

      assert_raises(Inferno::SkipException) do
        @sequence.run_test(@test)
      end
    end
  end

  describe 'conformance oauth endpoints test' do
    before do
      @test = @sequence_class[:read_conformance_oauth_endpoins]
      @sequence = @sequence_class.new(@instance, @client)
    end

    it 'succeeds when conformance has required oauth endpoints' do
      stub_request(:get, @conformance_endpoint)
        .to_return(
          status: 200,
          body: @conformance.to_json
        )

      @sequence.run_test(@test)
      assert @instance.oauth_token_endpoint == 'https://bulk-data.smarthealthit.org/auth/token'
    end

    it 'fails when conformance does not have oauth extension' do
      invalid_conformance = @conformance.clone
      invalid_conformance['rest'][0]['security']['extension'] = nil
      stub_request(:get, @conformance_endpoint)
        .to_return(
          status: 200,
          body: @conformance.to_json
        )

      assert_raises(Inferno::AssertionException) do
        @sequence.run_test(@test)
      end
    end

    it 'fails when conformance does not have token endpoint' do
      invalid_conformance = @conformance.clone
      invalid_conformance['rest'][0]['security']['extension'][0]['extension'].shift
      stub_request(:get, @conformance_endpoint)
        .to_return(
          status: 200,
          body: @conformance.to_json
        )

      assert_raises(Inferno::AssertionException) do
        @sequence.run_test(@test)
      end
    end

    it 'fails when conformance token endpoint does not have url' do
      invalid_conformance = @conformance.clone
      invalid_conformance['rest'][0]['security']['extension'][0]['extension'][0]['url'] = 'This is not a url'
      stub_request(:get, @conformance_endpoint)
        .to_return(
          status: 200,
          body: @conformance.to_json
        )

      assert_raises(Inferno::AssertionException) do
        @sequence.run_test(@test)
      end
    end
  end
end
