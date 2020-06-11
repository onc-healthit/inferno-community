# frozen_string_literal: true

require_relative '../../../../test/test_helper'

describe Inferno::Sequence::OncStandaloneOpenIDConnectSequence do
  def create_signed_token(payload: @payload, key_pair: @key_pair, kid: @jwk.kid)
    JWT.encode(payload, key_pair, 'RS256', kid: kid)
  end

  before do
    @key_pair = OpenSSL::PKey::RSA.new(2048)
    @oidc_configuration = load_json_fixture(:openid_configuration)
    @issuer = @oidc_configuration['issuer']
    @client_id = 'CLIENT_ID'

    @payload = {
      iss: @issuer,
      exp: 1.hour.from_now.to_i,
      nbf: Time.now.to_i,
      iat: Time.now.to_i,
      aud: @client_id,
      sub: SecureRandom.uuid,
      fhirUser: 'https://www.example.com/fhir/Patient/123'
    }

    @jwk = JWT::JWK.new(@key_pair)
    @jwk_hash = @jwk.export
    @signed_id_token = create_signed_token

    @sequence_class = Inferno::Sequence::OncStandaloneOpenIDConnectSequence

    @instance = Inferno::Models::TestingInstance.create(
      url: 'bad',
      onc_sl_url: 'http://www.example.com',
      onc_sl_scopes: ' patient/*.read openid fhirUser',
      onc_sl_client_id: 'CLIENT_ID',
      id_token: @signed_id_token
    )

    @client = FHIR::Client.new(@instance.onc_sl_url)

    @instance.instance_variable_set(:'@module', OpenStruct.new(fhir_version: 'r4'))

    @decoded_payload, @decoded_header = JWT.decode(@signed_id_token, @key_pair.public_key, false)

    @sequence = @sequence_class.new(@instance, @client)
    @sequence.instance_variable_set(:@decoded_payload, @decoded_payload)
    @sequence.instance_variable_set(:@decoded_header, @decoded_header)
    @sequence.instance_variable_set(:@oidc_configuration, @oidc_configuration)
  end

  describe 'token can be decoded test' do
    before do
      @test = @sequence_class[:decode_token]
    end

    it 'skips if id token scopes were not requested' do
      invalid_scopes = [
        'launch patient/*.read',
        'launch patient/*.read openid',
        'launch patient/*.read fhirUser'
      ]
      invalid_scopes.each do |scopes|
        @instance.update(onc_sl_scopes: scopes)

        exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

        assert_equal '"openid" and "fhirUser" scopes not requested', exception.message
      end
    end

    it 'fails if no id token is present' do
      @instance.update(id_token: nil)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Launch context did not contain an id token', exception.message
    end

    it 'fails if the id token is not a properly constructed jwt' do
      @instance.update(id_token: 'abc')

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_match(/ID token is not a properly constructed JWT:/, exception.message)
    end

    it 'succeeds if the id token is a properly constructed jwt' do
      @sequence.run_test(@test)
    end
  end

  describe 'well-known configuration retrieval test' do
    before do
      @test = @sequence_class[:retrieve_configuration]
    end

    it 'skips if id token scopes were not requested' do
      invalid_scopes = [
        'launch patient/*.read',
        'launch patient/*.read openid',
        'launch patient/*.read fhirUser'
      ]
      invalid_scopes.each do |scopes|
        @instance.update(onc_sl_scopes: scopes)

        exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

        assert_equal '"openid" and "fhirUser" scopes not requested', exception.message
      end
    end

    it 'skips if id token could not be decoded' do
      @sequence.instance_variable_set(:@decoded_payload, nil)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'ID token could not be decoded', exception.message
    end

    it 'fails if the configuration returns a non-200 response' do
      stub_request(:get, @issuer.chomp('/') + '/.well-known/openid-configuration')
        .to_return(status: 404)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 404. ', exception.message
    end

    it 'fails if the configuration does not have a content type of application/json' do
      stub_request(:get, @issuer.chomp('/') + '/.well-known/openid-configuration')
        .to_return(status: 200)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected content-type application/json but found ', exception.message
    end

    it 'fails if the configuration is not valid json' do
      stub_request(:get, @issuer.chomp('/') + '/.well-known/openid-configuration')
        .to_return(status: 200, headers: { 'content-type' => 'application/json' }, body: '{')

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Invalid JSON. ', exception.message
    end

    it 'succeeds if the configuration is valid json' do
      stub_request(:get, @issuer.chomp('/') + '/.well-known/openid-configuration')
        .to_return(status: 200, headers: { 'content-type' => 'application/json' }, body: '{}')

      @sequence.run_test(@test)
    end
  end

  describe 'required well-known configuration fields test' do
    before do
      @test = @sequence_class[:required_configuration_fields]
    end

    it 'skips if id token scopes were not requested' do
      invalid_scopes = [
        'launch patient/*.read',
        'launch patient/*.read openid',
        'launch patient/*.read fhirUser'
      ]
      invalid_scopes.each do |scopes|
        @instance.update(onc_sl_scopes: scopes)

        exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

        assert_equal '"openid" and "fhirUser" scopes not requested', exception.message
      end
    end

    it 'skips if id token could not be decoded' do
      @sequence.instance_variable_set(:@decoded_payload, nil)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'ID token could not be decoded', exception.message
    end

    it 'skips if the configuration could not be retrieved' do
      @sequence.instance_variable_set(:@oidc_configuration, nil)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'OpenID Connect well-known configuration could not be retrieved', exception.message
    end

    it 'fails if a required field is missing' do
      @sequence.required_configuration_fields.each do |field|
        config = @oidc_configuration.clone
        config.delete field
        @sequence.instance_variable_set(:@oidc_configuration, config)

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal "OpenID Connect well-known configuration missing required fields: #{field}", exception.message
      end
    end

    it 'fails if RSA SHA-256 signing is not supported' do
      config = @oidc_configuration.clone
      config['id_token_signing_alg_values_supported'].delete 'RS256'
      @sequence.instance_variable_set(:@oidc_configuration, config)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Signing tokens with RSA SHA-256 not supported', exception.message
    end

    it 'succeeds if the required configuration fields are present' do
      @sequence.run_test(@test)
    end
  end

  describe 'retrieve jwks test' do
    before do
      @test = @sequence_class[:retrieve_jwks]
    end

    it 'skips if id token scopes were not requested' do
      invalid_scopes = [
        'launch patient/*.read',
        'launch patient/*.read openid',
        'launch patient/*.read fhirUser'
      ]
      invalid_scopes.each do |scopes|
        @instance.update(onc_sl_scopes: scopes)

        exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

        assert_equal '"openid" and "fhirUser" scopes not requested', exception.message
      end
    end

    it 'skips if id token could not be decoded' do
      @sequence.instance_variable_set(:@decoded_payload, nil)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'ID token could not be decoded', exception.message
    end

    it 'skips if the configuration could not be retrieved' do
      @sequence.instance_variable_set(:@oidc_configuration, nil)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'OpenID Connect well-known configuration could not be retrieved', exception.message
    end

    it 'skips if the jwks_uri is blank' do
      config = @oidc_configuration.clone
      config['jwks_uri'] = ''
      @sequence.instance_variable_set(:@oidc_configuration, config)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'OpenID Connect well-known configuration did not contain a jwks_uri', exception.message
    end

    it 'fails if the jwks request returns a non-200 response' do
      stub_request(:get, @oidc_configuration['jwks_uri'])
        .to_return(status: 404)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 404. ', exception.message
    end

    it 'fails if the jwks request returns invalid json' do
      stub_request(:get, @oidc_configuration['jwks_uri'])
        .to_return(status: 200, body: '{')

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Invalid JSON. ', exception.message
    end

    it 'fails if the jwks keys field is not an array' do
      stub_request(:get, @oidc_configuration['jwks_uri'])
        .to_return(status: 200, body: { keys: { kty: 'RSA' } }.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'JWKS "keys" field must be an array', exception.message
    end

    it 'fails if the jwks contains an invalid key' do
      stub_request(:get, @oidc_configuration['jwks_uri'])
        .to_return(status: 200, body: { keys: [{ kty: 'RSA' }] }.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_match(/Invalid JWK:/, exception.message)
    end

    it 'fails if the jwks contains no RSA keys' do
      stub_request(:get, @oidc_configuration['jwks_uri'])
        .to_return(status: 200, body: { keys: [{ kty: 'xyz' }] }.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'JWKS contains no RSA keys', exception.message
    end

    it 'succeeds if the jwks contains a valid RSA keys' do
      stub_request(:get, @oidc_configuration['jwks_uri'])
        .to_return(status: 200, body: { keys: [@jwk.export] }.to_json)

      @sequence.run_test(@test)
    end
  end

  describe 'id token header test' do
    before do
      @test = @sequence_class[:token_header]
    end

    it 'skips if id token scopes were not requested' do
      invalid_scopes = [
        'launch patient/*.read',
        'launch patient/*.read openid',
        'launch patient/*.read fhirUser'
      ]
      invalid_scopes.each do |scopes|
        @instance.update(onc_sl_scopes: scopes)

        exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

        assert_equal '"openid" and "fhirUser" scopes not requested', exception.message
      end
    end

    it 'skips if id token could not be decoded' do
      @sequence.instance_variable_set(:@decoded_payload, nil)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'ID token could not be decoded', exception.message
    end

    it 'skips if the configuration could not be retrieved' do
      @sequence.instance_variable_set(:@oidc_configuration, nil)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'OpenID Connect well-known configuration could not be retrieved', exception.message
    end

    it 'skips if fetching keys from the jwks failed' do
      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'RSA keys could not be retrieved from JWKS', exception.message
    end

    it 'fails if the id token header does not specify the RS256 signing algorithm' do
      @sequence.instance_variable_set(:@jwks, [{}])
      @sequence.instance_variable_set(:@decoded_header, 'alg' => 'xyz')

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'ID Token signed with xyz rather than RS256', exception.message
    end

    describe 'with multiple RSA keys found' do
      before do
        @sequence.instance_variable_set(:@raw_jwks, keys: [1, 2])
        @sequence.instance_variable_set(:@jwks, [JWT::JWK.new(OpenSSL::PKey::RSA.new(2048)).export, @jwk_hash])
      end

      it 'fails if the header has no "kid" field' do
        @sequence.instance_variable_set(:@decoded_header, 'alg' => 'RS256')

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal '"kid" field must be present if JWKS contains multiple keys', exception.message
      end

      it 'fails if the jwks has no key with a matching "kid"' do
        @sequence.instance_variable_set(:@decoded_header, 'alg' => 'RS256', 'kid' => 'xyz')

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal 'JWKS did not contain an RS256 key with an id of xyz', exception.message
      end

      it 'succeeds if a matching key is found' do
        @sequence.run_test(@test)
      end
    end

    describe 'with a single RSA key found' do
      before do
        @sequence.instance_variable_set(:@raw_jwks, keys: [1])
        @sequence.instance_variable_set(:@jwks, [@jwk_hash])
      end

      it 'fails if a "kid" is present and it does not match the jwk' do
        @sequence.instance_variable_set(:@decoded_header, 'alg' => 'RS256', 'kid' => 'xyz')

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal 'JWKS did not contain an RS256 key with an id of xyz', exception.message
      end

      it 'succeeds if a "kid" is present and a matching key is found' do
        @sequence.run_test(@test)
      end

      it 'succeeds if no "kid" is present' do
        @instance.instance_variable_set(:@decoded_header, 'alg' => 'RS256')

        @sequence.run_test(@test)
      end
    end
  end

  describe 'id token payload test' do
    before do
      @test = @sequence_class[:token_payload]
      @sequence.instance_variable_set(:@jwk, @jwk_hash)
    end

    it 'skips if id token scopes were not requested' do
      invalid_scopes = [
        'launch patient/*.read',
        'launch patient/*.read openid',
        'launch patient/*.read fhirUser'
      ]
      invalid_scopes.each do |scopes|
        @instance.update(onc_sl_scopes: scopes)

        exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

        assert_equal '"openid" and "fhirUser" scopes not requested', exception.message
      end
    end

    it 'skips if id token could not be decoded' do
      @sequence.instance_variable_set(:@decoded_payload, nil)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'ID token could not be decoded', exception.message
    end

    it 'skips if the configuration could not be retrieved' do
      @sequence.instance_variable_set(:@oidc_configuration, nil)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'OpenID Connect well-known configuration could not be retrieved', exception.message
    end

    it 'skips if no jwk was found' do
      @sequence.instance_variable_set(:@jwk, nil)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No JWK was found', exception.message
    end

    it 'fails if any required claims are missing' do
      @sequence.required_payload_claims.each do |claim|
        payload = @decoded_payload.clone
        payload.delete claim
        @sequence.instance_variable_set(:@decoded_payload, payload)

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal "ID token missing required claims: #{claim}", exception.message
      end
    end

    it 'fails if the iss in invalid' do
      payload = @payload.clone
      payload[:iss] = 'BAD_ISS'
      token = create_signed_token(payload: payload)
      @instance.update(id_token: token)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_match(/Token validation error:.*iss/, exception.message)
    end

    it 'fails if the aud is invalid' do
      payload = @payload.clone
      payload[:aud] = 'BAD_AUD'
      token = create_signed_token(payload: payload)
      @instance.update(id_token: token)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_match(/Token validation error:.*aud/, exception.message)
    end

    it 'fails if the expiration time has passed' do
      payload = @payload.clone
      payload[:exp] = @payload[:exp] - 1.day.to_i
      token = create_signed_token(payload: payload)
      @instance.update(id_token: token)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_match(/Token validation error:.*exp/, exception.message)
    end

    it 'fails if the signature is invalid' do
      token = create_signed_token(payload: @payload, key_pair: OpenSSL::PKey::RSA.new(2048))
      @instance.update(id_token: token)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_match(/Token validation error:.*Signature/, exception.message)
    end

    it 'succeeds if the required claims are present' do
      @sequence.run_test(@test)
    end
  end

  describe 'fhirUser claim test' do
    before do
      @test = @sequence_class[:fhir_user_claim]
    end

    it 'skips if id token scopes were not requested' do
      invalid_scopes = [
        'launch patient/*.read',
        'launch patient/*.read openid',
        'launch patient/*.read fhirUser'
      ]
      invalid_scopes.each do |scopes|
        @instance.update(onc_sl_scopes: scopes)

        exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

        assert_equal '"openid" and "fhirUser" scopes not requested', exception.message
      end
    end

    it 'skips if id token could not be decoded' do
      @sequence.instance_variable_set(:@decoded_payload, nil)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'ID token could not be decoded', exception.message
    end

    it 'skips if the configuration could not be retrieved' do
      @sequence.instance_variable_set(:@oidc_configuration, nil)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'OpenID Connect well-known configuration could not be retrieved', exception.message
    end

    it 'fails if the fhirUser claim is not present' do
      payload = @decoded_payload.clone
      payload.delete 'fhirUser'
      @sequence.instance_variable_set(:@decoded_payload, payload)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'ID token does not contain `fhirUser` claim', exception.message
    end

    it 'fails if the fhirUser claim does not refer to an allowed FHIR resource type' do
      payload = @decoded_payload.clone
      payload['fhirUser'] = 'http://www.example.com/fhir/Condition/123'
      @sequence.instance_variable_set(:@decoded_payload, payload)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_match 'ID token `fhirUser` claim does not refer to a valid resource type ', exception.message
    end

    it 'fails if fetching the user is unsuccessful' do
      stub_request(:get, @decoded_payload['fhirUser'])
        .to_return(status: 404)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_match 'Bad response code: expected 200, 201, but found 404. ', exception.message
    end

    it 'fails if fetching the user returns invalid json' do
      stub_request(:get, @decoded_payload['fhirUser'])
        .to_return(status: 200, body: '{')

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_match 'Invalid JSON. ', exception.message
    end

    it 'fails if fetching the user does not return an allowed FHIR resource type' do
      stub_request(:get, @decoded_payload['fhirUser'])
        .to_return(status: 200, body: FHIR::Condition.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_match 'Resource from `fhirUser` claim was not an allowed resource type: Condition', exception.message
    end

    it 'succeeds if an allowed FHIR resource type is returned' do
      stub_request(:get, @decoded_payload['fhirUser'])
        .to_return(status: 200, body: FHIR::Patient.new.to_json)

      @sequence.run_test(@test)
    end
  end
end
