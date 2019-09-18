# frozen_string_literal: true

module Inferno
  module Sequence
    class SMARTDiscoverySequence < SequenceBase
      title 'SMART on FHIR Discovery'

      test_id_prefix 'SD'

      requires :url
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

      REQUIRED_WELL_KNOWN_FIELDS = [
        'authorization_endpoint',
        'token_endpoint',
        'capabilities'
      ].freeze

      RECOMMENDED_WELL_KNOWN_FIELDS = [
        'scopes_supported',
        'response_types_supported',
        'management_endpoint',
        'introspection_endpoint',
        'revocation_endpoint'
      ].freeze

      test 'Retrieve Configuration from well-known endpoint' do
        metadata do
          id '01'
          link 'http://www.hl7.org/fhir/smart-app-launch/conformance/#using-well-known'
          description %(
            The authorization endpoints accepted by a FHIR resource server can
            be exposed as a Well-Known Uniform Resource Identifier
          )
        end

        well_known_configuration_url = @instance.url.chomp('/') + '/.well-known/smart-configuration'
        well_known_configuration_response = LoggedRestClient.get(well_known_configuration_url)
        assert_response_ok(well_known_configuration_response)
        assert_response_content_type(well_known_configuration_response, 'application/json')
        assert_valid_json(well_known_configuration_response.body)

        @well_known_configuration = JSON.parse(well_known_configuration_response.body)
        @well_known_authorize_url = @well_known_configuration['authorization_endpoint']
        @well_known_token_url = @well_known_configuration['token_endpoint']
        @instance.update(
          oauth_authorize_endpoint: @well_known_authorize_url,
          oauth_token_endpoint: @well_known_token_url,
          oauth_register_endpoint: @well_known_configuration['registration_endpoint']
        )

        assert @well_known_configuration.present?, 'No .well-known/smart-configuration body'
      end

      test 'Configuration from well-known endpoint contains required fields' do
        metadata do
          id '02'
          link 'http://hl7.org/fhir/smart-app-launch/conformance/index.html#metadata'
          description %(
            The JSON from .well-known/smart-configuration contains the following
            required fields: #{REQUIRED_WELL_KNOWN_FIELDS.join(', ')}
          )
        end

        missing_fields = REQUIRED_WELL_KNOWN_FIELDS - @well_known_configuration.keys
        assert missing_fields.empty?, "The following required fields are missing: #{missing_fields.join(', ')}"
      end

      test 'Configuration from well-known endpoint contains recommended fields' do
        metadata do
          id '03'
          link 'http://hl7.org/fhir/smart-app-launch/conformance/index.html#metadata'
          optional
          description %(
            The JSON from .well-known/smart-configuration contains the following
            recommended fields: #{RECOMMENDED_WELL_KNOWN_FIELDS.join(', ')}
          )
        end

        missing_fields = RECOMMENDED_WELL_KNOWN_FIELDS - @well_known_configuration.keys
        assert missing_fields.empty?, "The following recommended fields are missing: #{missing_fields.join(', ')}"
      end

      test 'Conformance/Capability Statement provides OAuth 2.0 endpoints' do
        metadata do
          id '04'
link 'http://hl7.org/fhir/smart-app-launch/conformance/index.html#using-cs'
          description %(
            If a server requires SMART on FHIR authorization for access, its
            metadata must support automated discovery of OAuth2 endpoints
          )
        end

        @conformance = @client.conformance_statement
        oauth_metadata = @client.get_oauth2_metadata_from_conformance(false) # strict mode off, don't require server to state smart conformance
        assert !oauth_metadata.nil?, 'No OAuth Metadata in Conformance/CapabiliytStatemeent resource'
        @conformance_authorize_url = oauth_metadata[:authorize_url]
        @conformance_token_url = oauth_metadata[:token_url]
        assert @conformance_authorize_url.present?, 'No authorize URI provided in Conformance/CapabilityStatement resource'
        assert_valid_http_uri @conformance_authorize_url, "Invalid authorize url: '#{@conformance_authorize_url}'"
        assert @conformance_token_url.present?, 'No token URI provided in conformance statement.'
        assert_valid_http_uri @conformance_token_url, "Invalid token url: '#{@conformance_token_url}'"

        warning do
          service = []
          @conformance.try(:rest)&.each do |endpoint|
            endpoint.try(:security).try(:service)&.each do |sec_service|
              sec_service.try(:coding)&.each do |coding|
                service << coding.code
              end
            end
          end

          assert !service.empty?, 'No security services listed. Conformance/CapabilityStatement.rest.security.service should be SMART-on-FHIR.'
          assert service.any? { |any_service| any_service == 'SMART-on-FHIR' }, "Conformance/CapabilityStatement.rest.security.service set to #{service.map { |e| "'" + e + "'" }.join(', ')}.  It should contain 'SMART-on-FHIR'."
        end

        registration_url = nil

        warning do
          security_info = @conformance.rest.first.security.extension.find { |x| x.url == 'http://fhir-registry.smarthealthit.org/StructureDefinition/oauth-uris' }
          registration_url = security_info.extension.find { |x| x.url == 'register' }
          registration_url = registration_url.value if registration_url
          assert registration_url.present?, 'No dynamic registration endpoint in conformance.'
          assert_valid_http_uri registration_url, "Invalid registration url: '#{registration_url}'"

          manage_url = security_info.extension.find { |x| x.url == 'manage' }
          manage_url = manage_url.value if manage_url
          assert manage_url.present?, 'No user-facing authorization management workflow entry point for this FHIR server.'
        end

        @instance.update(
          oauth_authorize_endpoint: @conformance_authorize_url,
          oauth_token_endpoint: @conformance_token_url,
          oauth_register_endpoint: registration_url
        )
      end

      test 'OAuth Endpoints must be the same in the conformance statement and well known endpoint' do
        metadata do
          id '05'
link 'http://hl7.org/fhir/smart-app-launch/conformance/index.html#using-cs'
          description %(
            If a server requires SMART on FHIR authorization for access, its
            metadata must support automated discovery of OAuth2 endpoints
          )
        end

        assert @well_known_authorize_url == @conformance_authorize_url, 'The authorization url is not consistent between the well-known endpoint response and the conformance statement'

        assert @well_known_token_url == @conformance_token_url, 'The token url is not consistent between the well-known endpoint response and the conformance statement'
      end
    end
  end
end
