# frozen_string_literal: true

require File.expand_path '../test_helper.rb', __dir__

describe FHIR::Client do
  before do
    @client = FHIR::Client.new('http://www.example.com/fhir')
    @instance = Inferno::Models::TestingInstance.create(
      oauth_token_endpoint: 'http://www.example.com/token',
      client_id: 'CLIENT_ID'
    )
    @client.instance_variable_set(:@testing_instance, @instance)
  end

  describe '#time_to_refresh?' do
    it 'returns true if the token expiration time is unknown' do
      assert_equal true, @client.time_to_refresh?
    end

    it 'returns false if the token expiration time is more than a minute in the future' do
      now = DateTime.now
      @instance.update(token_retrieved_at: now)
      [now + 65.seconds, now + 1.hour, now + 1.year].each do |time|
        expires_in = time.to_i - now.to_i
        @instance.update(token_expires_in: expires_in)

        assert_equal false, @client.time_to_refresh?
      end
    end

    it 'returns trueif the token has expired or is about to expire' do
      now = DateTime.now
      @instance.update(token_retrieved_at: now)
      [now + 55.seconds, now - 1.hour, now - 1.year].each do |time|
        expires_in = time.to_i - now.to_i
        @instance.update(token_expires_in: expires_in)

        assert_equal true, @client.time_to_refresh?
      end
    end
  end

  describe '#perform_refresh' do
    before do
      @refresh_token = 'OLD_REFRESH_TOKEN'
      @access_token = 'OLD_ACCESS_TOKEN'
      @expires_in = 123
      @instance.update(
        refresh_token: @refresh_token,
        token: @access_token,
        token_expires_in: @expires_in
      )

      @new_refresh_token = 'NEW_REFRESH_TOKEN'
      @new_access_token = 'NEW_ACCESS_TOKEN'
      @new_expires_in = 456
      @token_response = {
        refresh_token: @new_refresh_token,
        access_token: @new_access_token,
        expires_in: @new_expires_in
      }
    end

    it 'does not update the token if the refresh is unsuccessful' do
      stub_request(:post, @instance.oauth_token_endpoint)
        .with(body: {
                grant_type: 'refresh_token',
                refresh_token: @instance.refresh_token,
                client_id: @instance.client_id
              })
        .to_return(status: 500)

      @client.perform_refresh
      assert_equal @refresh_token, @instance.refresh_token
      assert_equal @access_token, @instance.token
      assert_equal @expires_in, @instance.token_expires_in
    end

    it 'updates the token if the refresh is successful for public clients' do
      stub_request(:post, @instance.oauth_token_endpoint)
        .with(body: {
                grant_type: 'refresh_token',
                refresh_token: @instance.refresh_token,
                client_id: @instance.client_id
              })
        .to_return(status: 200, body: @token_response.to_json)

      @client.perform_refresh

      assert_equal @new_refresh_token, @instance.refresh_token
      assert_equal @new_access_token, @instance.token
      assert_equal @new_expires_in, @instance.token_expires_in
    end

    it 'updates the token if the refresh is successful for confidential clients' do
      @instance.update(
        client_secret: 'CLIENT_SECRET',
        confidential_client: true
      )
      stub_request(:post, @instance.oauth_token_endpoint)
        .with(
          body: {
            grant_type: 'refresh_token',
            refresh_token: @instance.refresh_token
          },
          headers: { 'Authorization': @client.encoded_secret(@instance.client_id, @instance.client_secret) }
        )
        .to_return(status: 200, body: @token_response.to_json)

      @client.perform_refresh

      assert_equal @new_refresh_token, @instance.refresh_token
      assert_equal @new_access_token, @instance.token
      assert_equal @new_expires_in, @instance.token_expires_in
    end

    it 'sets expires_in to nil if it is non-numeric' do
      @token_response[:expires_in] = 'abc'
      stub_request(:post, @instance.oauth_token_endpoint)
        .with(body: {
                grant_type: 'refresh_token',
                refresh_token: @instance.refresh_token,
                client_id: @instance.client_id
              })
        .to_return(status: 200, body: @token_response.to_json)

      @client.perform_refresh

      assert_equal @new_refresh_token, @instance.refresh_token
      assert_equal @new_access_token, @instance.token
      assert_nil @instance.token_expires_in
    end
  end
end
