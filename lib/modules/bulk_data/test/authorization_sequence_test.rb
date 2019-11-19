# frozen_string_literal: true

require_relative '../../../../test/test_helper'

describe Inferno::Sequence::BulkDataAuthorizationSequence do
  before do
    @sequence_class = Inferno::Sequence::BulkDataAuthorizationSequence
    config = load_json_fixture(:bulk_data_authorization)

    @instance = Inferno::Models::TestingInstance.create(
      url: 'http://www.example.com',
      client_id: config['client_id'],
      bulk_public_key: config['public_key'].to_json,
      bulk_private_key: config['private_key'].to_json,
      oauth_token_endpoint: config['token_url']
    )

    @client = FHIR::Client.new(@instance.url)

    @access_token = {
      'token_type' => 'bearer',
      'expires_in' => 900,
      'access_token' => 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoiYmVhcmVyIiwiZXhwaXJlc19pbiI6OTAwLCJpYXQiOjE1NzM5NDU1MDQsImV4cCI6MTU3Mzk0NjQwNH0.Ds-9HxQPJshkPYYBowJXltTaX2T6MSv_qYnZLjteTH8'
    }
  end

  describe 'return access token tests' do
    before do
      @test = @sequence_class[:return_access_token]
      @sequence = @sequence_class.new(@instance, @client)
    end

    it 'success when server returns access token' do
      stub_request(:post, @instance.oauth_token_endpoint)
        .to_return(
          status: 200,
          headers: { content_type: 'application/json' },
          body: @access_token.to_json
        )

      @sequence.run_test(@test)
    end

    it 'fail when server returns status other than 200' do
      stub_request(:post, @instance.oauth_token_endpoint)
        .to_return(
          status: 400
        )

      assert_raises(Inferno::AssertionException) do
        @sequence.run_test(@test)
      end
    end
   
    it 'fail when server returns empty access_token' do
      invalid_access_token = @access_token.clone
      invalid_access_token['access_token'] = nil
      
      stub_request(:post, @instance.oauth_token_endpoint)
        .to_return(
          status: 400,
          body: invalid_access_token.to_json
        )

      assert_raises(Inferno::AssertionException) do
        @sequence.run_test(@test)
      end
    end
  end
end
