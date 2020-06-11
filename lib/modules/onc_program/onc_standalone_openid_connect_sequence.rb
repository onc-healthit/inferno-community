# frozen_string_literal: true

require_relative 'onc_openid_connect_sequence'

module Inferno
  module Sequence
    class OncStandaloneOpenIDConnectSequence < OncOpenIDConnectSequence
      extends_sequence OncOpenIDConnectSequence
      title 'OpenID Connect'
      description 'Authenticate users with OpenID Connect for OAuth 2.0.'

      test_id_prefix 'SA-OIDC'

      requires :id_token, :onc_sl_client_id
      defines :oauth_introspection_endpoint

      details %(
        # Background

        OpenID Connect (OIDC) provides the ability to verify the identity of the
        authorizing user. Within the [SMART App Launch
        Framework](http://hl7.org/fhir/smart-app-launch/), Applications can
        request an `id_token` be provided with by including the `openid
        fhirUser` scopes when requesting authorization.

        # Test Methodology

        This sequence validates the id token returned as part of the OAuth 2.0
        token response. Once the token is decoded, the server's OIDC
        configuration is retrieved from its well-known configuration endpoint.
        This configuration is checked to ensure that all required fields are
        present. Next the keys used to cryptographically sign the id token are
        retrieved from the url contained in the OIDC configuration. Then the
        header, payload, and signature of the id token are validated. Finally,
        the FHIR resource from the `fhirUser` claim in the id token is fetched
        from the FHIR server.

        For more information see:

        * [SMART App Launch Framework](http://hl7.org/fhir/smart-app-launch/)
        * [Scopes for requesting identity data](http://hl7.org/fhir/smart-app-launch/scopes-and-launch-context/index.html#scopes-for-requesting-identity-data)
        * [Apps Requesting Authorization](http://hl7.org/fhir/smart-app-launch/#step-1-app-asks-for-authorization)
        * [OpenID Connect Core](https://openid.net/specs/openid-connect-core-1_0.html)
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

      def instance_client_secret
        @instance.onc_sl_client_secret
      end

      def instance_confidential_client
        @instance.onc_sl_confidential_client
      end

      def instance_scopes
        @instance.onc_sl_scopes
      end
    end
  end
end
