# frozen_string_literal: true

require_relative 'onc_smart_discovery_sequence'

module Inferno
  module Sequence
    class OncStandaloneSMARTDiscoverySequence < OncSMARTDiscoverySequence
      extends_sequence OncSMARTDiscoverySequence

      title 'SMART on FHIR Discovery'

      test_id_prefix 'SA-OSD'

      requires :onc_sl_url
      defines :oauth_authorize_endpoint, :oauth_token_endpoint, :oauth_register_endpoint

      description "Retrieve server's SMART on FHIR configuration"

      details %(
        # Background

        The #{title} Sequence test looks for authorization endpoints and SMART
        capabilities as described by the [SMART App Launch
        Framework](http://hl7.org/fhir/smart-app-launch/conformance/index.html).
        The SMART launch framework uses OAuth 2.0 to *authorize* apps, like
        Inferno, to access certain information on a FHIR server. The
        authorization service accessed at the endpoint allows users to give
        these apps permission without sharing their credentials with the
        application itself. Instead, the application receives an access token
        which allows it to access resources on the server. The access token
        itself has a limited lifetime and permission scopes associated with it.
        A refresh token may also be provided to the application in order to
        obtain another access token. Unlike access tokens, a refresh token is
        not shared with the resource server. If OpenID Connect is used, an id
        token may be provided as well. The id token can be used to
        *authenticate* the user. The id token is digitally signed and allows the
        identity of the user to be verified.

        # Test Methodology

        This test suite will examine the SMART on FHIR configuration contained
        in both the `/metadata` and `/.well-known/smart-configuration`
        endpoints.

        For more information see:

        * [SMART App Launch Framework](http://hl7.org/fhir/smart-app-launch/index.html)
        * [The OAuth 2.0 Authorization Framework](https://tools.ietf.org/html/rfc6749)
        * [OpenID Connect Core](https://openid.net/specs/openid-connect-core-1_0.html)
      )

      def url_property
        'onc_sl_url'
      end

      def after_save_oauth_endpoints(oauth_token_endpoint, oauth_authorize_endpoint)
        @instance.onc_sl_oauth_token_endpoint = oauth_token_endpoint
        @instance.onc_sl_oauth_authorize_endpoint = oauth_authorize_endpoint
        @instance.save!
      end
    end
  end
end
