# frozen_string_literal: true

require_relative './shared_onc_launch_tests'

module Inferno
  module Sequence
    class OncEHRLaunchSequence < SequenceBase
      include Inferno::Sequence::SharedONCLaunchTests

      title 'ONC EHR Launch Sequence'

      description 'Demonstrate the ONC SMART EHR Launch Sequence.'

      test_id_prefix 'OELS'

      requires :url,
               :client_id,
               :confidential_client,
               :client_secret,
               :scopes,
               :oauth_authorize_endpoint,
               :oauth_token_endpoint,
               :initiate_login_uri,
               :redirect_uris

      defines :token, :id_token, :refresh_token, :patient_id

      show_uris

      def valid_resource_types
        [
          '*',
          'Patient',
          'AllergyIntolerance',
          'CarePlan',
          'CareTeam',
          'Condition',
          'Device',
          'DiagnosticReport',
          'DocumentReference',
          'Encounter',
          'Goal',
          'Immunization',
          'Location',
          'Medication',
          'MedicationOrder',
          'MedicationRequest',
          'MedicationStatement',
          'Observation',
          'Organization',
          'Practitioner',
          'PractitionerRole',
          'Procedure',
          'Provenance',
          'RelatedPerson'
        ]
      end

      def required_scopes
        ['openid', 'fhirUser', 'launch', 'offline_access']
      end

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

      auth_endpoint_tls_test(index: '03')

      test 'OAuth 2.0 server redirects client browser to Inferno app redirect URI' do
        metadata do
          id '04'
          link 'http://www.hl7.org/fhir/smart-app-launch/'
          description %(
           Client browser redirected from OAuth 2.0 server to redirect URI of
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

      required_scope_test(index: '12', patient_or_user: 'user')

      test :unauthorized_read do
        metadata do
          id '13'
          name 'Server rejects unauthorized access'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html#behavior'
          description %(
            A server SHALL reject any unauthorized requests by returning an HTTP
            401 unauthorized response code.
          )
          versions :r4
        end

        @client.set_no_auth
        skip_if_auth_failed

        reply = @client.read(FHIR::Patient, @instance.patient_id)
        @client.set_bearer_token(@instance.token)

        assert_response_unauthorized reply
      end

      patient_context_test(index: '14')

      test :smart_style_url do
        metadata do
          id '15'
          link 'http://www.hl7.org/fhir/smart-app-launch/scopes-and-launch-context/index.html#styling'
          name 'Launch context contains smart_style_url which links to valid JSON'
          description %(
            In order to mimic the style of the SMART host more closely, SMART
            apps can check for the existence of this launch context parameter
            and download the JSON file referenced by the URL value.
          )
        end

        skip_if_auth_failed

        skip_if @token_response_body.blank?, 'No valid token response received'

        assert @token_response_body['smart_style_url'].present?, 'Token response did not contain smart_style_url'

        response = LoggedRestClient.get(@token_response_body['smart_style_url'])
        assert_response_ok(response)
        assert_valid_json(response.body)
      end

      test :need_patient_banner do
        metadata do
          id '16'
          link 'http://www.hl7.org/fhir/smart-app-launch/scopes-and-launch-context/index.html#launch-context-arrives-with-your-access_token'
          name 'Launch context contains need_patient_banner'
          description %(
            `need_patient_banner` is a boolean value indicating whether the app
            was launched in a UX context where a patient banner is required
            (when true) or not required (when false).
          )
        end

        skip_if_auth_failed

        skip_if @token_response_body.blank?, 'No valid token response received'

        assert @token_response_body.key?('need_patient_banner'), 'Token response did not contain need_patient_banner'
      end
    end
  end
end
