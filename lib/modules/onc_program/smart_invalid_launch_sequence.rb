# frozen_string_literal: true

module Inferno
  module Sequence
    class SMARTInvalidLaunchSequence < SequenceBase
      include Inferno::Sequence::SharedONCLaunchTests
      title 'SMART App Launch Error: Invalid Launch Parameter'
      description 'Demonstrate that the server properly validates LAUNCH parameter'

      test_id_prefix 'SIL'

      requires :url,
               :client_id,
               :confidential_client,
               :client_secret,
               :scopes,
               :oauth_authorize_endpoint,
               :oauth_token_endpoint,
               :initiate_login_uri,
               :redirect_uris

      show_uris

      details %(
        # Background

        The Invalid Launch Parameter Sequence verifies that a SMART Launch Sequence,
        specifically the [EHR
        Launch](http://www.hl7.org/fhir/smart-app-launch/#ehr-launch-sequence)
        Sequence, does not work in the case where the client sends an invalid
        FHIR server as the `launch` parameter during launch.  This must fail to ensure
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
        'url'
      end

      def instance_url
        @instance.send(url_property)
      end

      def instance_client_id
        @instance.client_id
      end

      def instance_confidential_client
        @instance.confidential_client
      end

      def instance_client_secret
        @instance.client_secret
      end

      def instance_scopes
        @instance.scopes
      end

      test 'EHR server redirects client browser to Inferno app launch URI' do
        metadata do
          id '01'
          link 'http://www.hl7.org/fhir/smart-app-launch/'
          description %(
            Client browser sent from EHR server to app launch URI of client app
            as described in SMART EHR Launch Sequence.
          )
        end

        wait_at_endpoint 'launch'
      end

      test 'EHR provides iss and launch parameter to the Inferno app launch URI via the client browser querystring' do
        metadata do
          id '02'
          link 'http://www.hl7.org/fhir/smart-app-launch/'
          description %(
            The EHR is required to provide a reference to the EHR FHIR endpoint
            in the iss queystring parameter, and an opaque identifier for the
            launch in the launch querystring parameter.
          )
        end

        @client = FHIR::Client.for_testing_instance(@instance, url_property: 'url')
        @client.set_bearer_token(@instance.token) unless @client.nil? || @instance.nil? || @instance.token.nil?
        @client&.monitor_requests

        assert @params['iss'].present?, 'Expecting "iss" as a querystring parameter.'
        assert @params['launch'].present?, 'Expecting "launch" as a querystring parameter.'

        warning do
          assert @params['iss'] == @instance.url, "'iss' param [#{@params['iss']}] does not match url of testing instance [#{@instance.url}]"
        end
      end

      test 'Inferno redirects client browser to authorization service and is redirected back to Inferno.' do
        metadata do
          id '03'
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
          'client_id' => @instance.client_id,
          'redirect_uri' => @instance.redirect_uris,
          'scope' => @instance.scopes,
          'launch' => SecureRandom.uuid, # overwrite with an invalid launch parameter
          'state' => @instance.state,
          'aud' => @params['iss']
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
          id '04'
          name 'Inferno client app does not receive code parameter redirect URI'
          link 'http://www.hl7.org/fhir/smart-app-launch/'
          description %(
            Inferno redirected the user to the authorization service with an invalid launch parameter.
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
        pass 'Tester attested that the authorization did not succeed due to invalid LAUNCH parameter.' if @params['confirm_fail']
      end
    end
  end
end
