# frozen_string_literal: true

require_relative '../../test_helper'

describe Inferno::Sequence::BulkDataDiscoverySequence do
  SEQUENCE = Inferno::Sequence::BulkDataDiscoverySequence

  before do
    @instance = Inferno::Models::TestingInstance.create(
      url: 'http://www.example.com'
    )

    @client = FHIR::Client.new(@instance.url)
    @well_known_endpoint = @instance.url + '/.well-known/smart-configuration'
    @smart_configuration = {
      'token_endpoint' => 'https://www.example.com/auth/token',
      'token_endpoint_auth_methods_supported' => ['private_key_jwt'],
      'token_endpoint_auth_signing_alg_values_supported' => ['RS384', 'ES384'],
      'scopes_supported' => ['system/*.read'],
      'registration_endpoint' => 'https://www.example.com/auth/register'
    }
  end

  describe 'read well known endpoints tests' do
    before do
      @test = SEQUENCE[:read_well_known_endpoint]
      @sequence = SEQUENCE.new(@instance, @client)
    end

    it 'succeeds when server returns smart configuration' do
      stub_request(:get, @well_known_endpoint)
        .to_return(
          status: 200,
          headers: {content_type: 'application/json'},
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
      
      assert_raises(Inferno::AssertionException){
        @sequence.run_test(@test)
      }
    end
  end
  
end