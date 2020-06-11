# frozen_string_literal: true

module Inferno
  module Sequence
    class TokenRevocationSequence < SequenceBase
      title 'Token Revocation'
      description 'Demonstrate the Health IT module is capable of revoking access granted to an application.'

      test_id_prefix 'TR'

      requires :onc_sl_url, :onc_sl_token, :onc_sl_refresh_token, :onc_sl_patient_id, :onc_sl_oauth_token_endpoint, :onc_visual_token_revocation, :onc_visual_token_revocation_notes

      def encoded_secret(client_id, client_secret)
        "Basic #{Base64.strict_encode64(client_id + ':' + client_secret)}"
      end

      test 'Health IT developer demonstrated the ability of the Health IT Module to revoke tokens.' do
        metadata do
          id '01'
          link 'https://www.federalregister.gov/documents/2020/05/01/2020-07419/21st-century-cures-act-interoperability-information-blocking-and-the-onc-health-it-certification'
          description %(
            Health IT developer demonstrated the ability of the Health IT Module / authorization server to revoke tokens.
          )
        end

        assert @instance.onc_visual_token_revocation == 'true', 'Health IT Module did not demonstrate the ability of the Health IT Module / authorization server to revoke tokens'
        pass @instance.onc_visual_token_revocation_notes if @instance.onc_visual_token_revocation_notes.present?
      end

      test :validate_rejected do
        metadata do
          id '02'
          name 'Access to Patient resource returns unauthorized after token revocation.'
          link 'https://www.federalregister.gov/documents/2020/05/01/2020-07419/21st-century-cures-act-interoperability-information-blocking-and-the-onc-health-it-certification'
          description %(
            This test checks that the Patient resource returns unuathorized after token revocation.
          )
        end
        skip_if @instance.onc_sl_patient_id.nil?, 'Patient ID not provided to test. The patient ID is typically provided during in a SMART launch context.'
        skip_if @instance.onc_sl_token.nil?, 'Bearer token not provided.  This test verifies that the bearer token can no longer be used to access a Patient resource.'

        @client = FHIR::Client.for_testing_instance(@instance, url_property: 'onc_sl_url')
        @client.set_bearer_token(@instance.onc_sl_token) unless @client.nil? || @instance.nil? || @instance.onc_sl_token.nil?
        @client&.monitor_requests

        reply = @client.read(FHIR::Patient, @instance.onc_sl_patient_id)

        assert_response_unauthorized reply
      end

      test :refresh_rejected do
        metadata do
          id '03'
          name 'Token refresh fails after token revocation.'
          link 'http://www.hl7.org/fhir/smart-app-launch/'
          description %(
            This test checks that refreshing token fails after token revokation.
          )
        end
        skip_if @instance.onc_sl_refresh_token.nil?, 'Refresh token not ID not provided to test.'

        oauth2_params = {
          'grant_type' => 'refresh_token',
          'refresh_token' => @instance.onc_sl_refresh_token
        }
        oauth2_headers = { 'Content-Type' => 'application/x-www-form-urlencoded' }

        oauth2_headers['Authorization'] = encoded_secret(@instance.onc_sl_client_id, @instance.onc_sl_client_secret) if @instance.onc_sl_confidential_client

        token_response = LoggedRestClient.post(@instance.onc_sl_oauth_token_endpoint, oauth2_params, oauth2_headers)

        assert_response_bad_or_unauthorized token_response
      end
    end
  end
end
