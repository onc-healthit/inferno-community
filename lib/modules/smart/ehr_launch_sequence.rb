# frozen_string_literal: true

require_relative './shared_launch_tests'

module Inferno
  module Sequence
    class EHRLaunchSequence < SequenceBase
      include SharedLaunchTests

      title 'EHR Launch Sequence'
      description 'Demonstrate the SMART EHR Launch Sequence.'
      test_id_prefix 'ELS'

      requires :client_id,
               :client_secret,
               :confidential_client,
               :initiate_login_uri,
               :oauth_authorize_endpoint,
               :oauth_token_endpoint,
               :redirect_uris,
               :scopes

      defines :token, :id_token, :refresh_token, :patient_id

      details %(
        # Background

        The [EHR
        Launch](http://hl7.org/fhir/smart-app-launch/index.html#ehr-launch-sequence)
        is one of two ways in which an app can be launched, the other being
        Standalone launch. In an EHR launch, the app is launched from an
        existing EHR session or portal by a redirect to the registered launch
        URL. The EHR provides the app two parameters:

        * `iss` - Which contains the FHIR server url
        * `launch` - An identifier needed for authorization

        # Test Methodology

        Inferno will wait for the EHR server redirect upon execution. When the
        redirect is received Inferno will check for the presence of the `iss`
        and `launch` parameters. The security of the authorization endpoint is
        then checked and authorization is attempted using the provided `launch`
        identifier.

        For more information on the #{title} see:

        * [SMART EHR Launch Sequence](http://hl7.org/fhir/smart-app-launch/index.html#ehr-launch-sequence)
      )

      test 'EHR server redirects client browser to app launch URI' do
        metadata do
          id '01'
          link 'http://www.hl7.org/fhir/smart-app-launch/'
          description %(
            Client browser sent from EHR server to launch URI of client app as
            described in SMART EHR Launch Sequence.
          )
        end

        wait_at_endpoint 'launch'
      end

      test 'EHR provides iss and launch parameter to the launch URI via the client browser querystring' do
        metadata do
          id '02'
          link 'http://www.hl7.org/fhir/smart-app-launch/'
          description %(
            The EHR is required to provide a reference to the EHR FHIR endpoint
            in the iss queystring parameter, and an opaque identifier for the
            launch in the launch querystring parameter.
          )
        end

        assert @params['iss'].present?, 'Expecting "iss" as a querystring parameter.'
        assert @params['launch'].present?, 'Expecting "launch" as a querystring parameter.'

        warning do
          assert @params['iss'] == @instance.url, "'iss' param [#{@params['iss']}] does not match url of testing instance [#{@instance.url}]"
        end
      end

      auth_endpoint_tls_test(index: '03')

      test 'OAuth server redirects client browser to app redirect URI' do
        metadata do
          id '04'
          link 'http://www.hl7.org/fhir/smart-app-launch/'
          description %(
           Client browser redirected from OAuth server to redirect URI of client
           app as described in SMART authorization sequence.
          )
        end

        @instance.save
        @instance.update(state: SecureRandom.uuid)

        oauth2_params = {
          'response_type' => 'code',
          'client_id' => @instance.client_id,
          'redirect_uri' => @instance.redirect_uris,
          'scope' => @instance.scopes,
          'launch' => @params['launch'],
          'state' => @instance.state,
          'aud' => @params['iss']
        }

        oauth2_auth_query = @instance.oauth_authorize_endpoint + '?'
        oauth2_params.each do |key, value|
          oauth2_auth_query += "#{key}=#{CGI.escape(value)}&" unless value.nil? || key.nil?
        end

        redirect oauth2_auth_query[0..-2], 'redirect'
      end

      code_and_state_received_test(index: '05')

      token_endpoint_tls_test(index: '06')

      invalid_code_test(index: '07')

      invalid_client_id_test(index: '08')

      successful_token_exchange_test(index: '09')

      token_response_contents_test(index: '10')

      token_response_headers_test(index: '11')
    end
  end
end
