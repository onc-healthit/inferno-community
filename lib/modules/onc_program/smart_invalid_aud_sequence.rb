# frozen_string_literal: true

module Inferno
  module Sequence
    class SMARTInvalidAudSequence < SequenceBase
      include Inferno::Sequence::SharedONCLaunchTests
      title 'SMART App Launch Error: Invalid AUD Parameter'
      description 'Demonstrate that the server properly validates AUD parameter'

      test_id_prefix 'SIA'

      requires :onc_sl_client_id,
               :onc_sl_confidential_client,
               :onc_sl_client_secret,
               :onc_sl_scopes,
               :oauth_authorize_endpoint,
               :oauth_token_endpoint,
               :initiate_login_uri,
               :redirect_uris

      show_uris

      INVALID_AUD_URL = 'https://inferno.healthit.gov/invalid_aud'

      details %(
        # Background

        The Invalid AUD Sequence verifies that a SMART Launch Sequence,
        specifically the [Standalone
        Launch](http://hl7.org/fhir/smart-app-launch/#standalone-launch-sequence)
        Sequence, does not work in the case where the client sends an invalid
        FHIR server as the `aud` parameter during launch.  This must fail to ensure
        that a genuine bearer token is not leaked to a counterfit resource server.

        This test is not included as part of a regular SMART Launch Sequence
        because it requires the browser of the user to be redirected to the authorization
        service, and there is no expectation that the authorization service redirects
        the user back to Inferno with an error message.  The only requirement is that
        Inferno is not granted a code to exchange for a valid access token.  Since
        this is a special case, it is tested independently in a separate sequence.

        Note that this test will launch a new browser window.  The user is required to
        'Attest' in the Inferno user interface after the launch does not succeed,
        if the server does not return an error code.
      )

      def url_property
        'onc_sl_url'
      end

      def instance_url
        @instance.send(url_property)
      end

      def instance_client_id
        @instance.onc_sl_client_id
      end

      def instance_confidential_client
        @instance.onc_sl_confidential_client
      end

      def instance_client_secret
        @instance.onc_sl_client_secret
      end

      def instance_scopes
        @instance.onc_sl_scopes
      end

      test 'Inferno redirects client browser to authorization service and is redirected back to Inferno.' do
        metadata do
          id '01'
          link 'http://www.hl7.org/fhir/smart-app-launch/'
          description %(
            Client browser redirected from OAuth server to redirect URI of
            client app as described in SMART authorization sequence.
          )
        end

        @instance.save
        @instance.update(state: SecureRandom.uuid)

        oauth2_params = {
          'response_type' => 'code',
          'client_id' => @instance.onc_sl_client_id,
          'redirect_uri' => @instance.redirect_uris,
          'scope' => instance_scopes,
          'state' => @instance.state,
          'aud' => INVALID_AUD_URL
        }

        oauth_authorize_endpoint = @instance.oauth_authorize_endpoint

        assert_valid_http_uri oauth_authorize_endpoint, "OAuth2 Authorization Endpoint: \"#{oauth_authorize_endpoint}\" is not a valid URI"

        oauth2_auth_query = oauth_authorize_endpoint

        oauth2_auth_query += if oauth_authorize_endpoint.include? '?'
                               '&'
                             else
                               '?'
                             end

        oauth2_params.each do |key, value|
          oauth2_auth_query += "#{key}=#{CGI.escape(value)}&"
        end

        redirect oauth2_auth_query[0..-2], 'redirect', true
      end

      test :code_and_state_received do
        metadata do
          id '02'
          name 'Inferno client app does not receive code parameter redirect URI'
          link 'http://www.hl7.org/fhir/smart-app-launch/'
          description %(
            Inferno redirected the user to the authorization service with an invalid AUD.
            Inferno expects that the authorization request will not succeed.  This can
            either be from the server explicitely pass an error, or stopping and the
            tester returns to Inferno to confirm that the server presented them a failure.
          )
        end

        @client = FHIR::Client.for_testing_instance(@instance, url_property: url_property)
        @client.set_bearer_token(@instance.token) unless @client.nil? || @instance.nil? || @instance.token.nil?
        @client&.monitor_requests

        skip_if @params.blank?, oauth_redirect_failed_message
        pass 'Server redirected the user back to the app without an access code.' if @params.blank?

        assert @params['code'].nil?, 'Authorization has incorrectly succeeded because access code provided to Inferno.'
        pass 'Server redirected the user back to the app with an error.' if @params['error'].present?
        pass 'Tester attested that the authorization service did not succeed due to invalid AUD parameter.' if @params['confirm_fail']
      end
    end
  end
end
