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

      SMART_OAUTH_EXTENSION_URL = 'http://fhir-registry.smarthealthit.org/StructureDefinition/oauth-uris'

      REQUIRED_OAUTH_ENDPOINTS = [
        { url: 'authorize', description: 'authorization' },
        { url: 'token', description: 'token' }
      ].freeze

      OPTIONAL_OAUTH_ENDPOINTS = [
        { url: 'register', description: 'dynamic registration' },
        { url: 'manage', description: 'authorization management' },
        { url: 'introspect', description: 'token introspection' },
        { url: 'revoke', description: 'token revocation' }
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
        @well_known_register_url = @well_known_configuration['registration_endpoint']
        @well_known_manage_url = @well_known_configuration['management_endpoint']
        @well_known_introspect_url = @well_known_configuration['introspection_endpoint']
        @well_known_revoke_url = @well_known_configuration['revocation_endpoint']

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
            required fields: #{REQUIRED_WELL_KNOWN_FIELDS.map { |field| "`#{field}`" }.join(', ')}
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
            recommended fields: #{RECOMMENDED_WELL_KNOWN_FIELDS.map { |field| "`#{field}`" }.join(', ')}
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

        assert oauth_metadata.present?, 'No OAuth Metadata in Conformance/CapabiliytStatemeent resource'

        REQUIRED_OAUTH_ENDPOINTS.each do |endpoint|
          url = oauth_metadata[:"#{endpoint[:url]}_url"]
          instance_variable_set(:"@conformance_#{endpoint[:url]}_url", url)

          assert url.present?, "No #{endpoint[:description]} URI provided in Conformance/CapabilityStatement resource"
          assert_valid_http_uri url, "Invalid #{endpoint[:description]} url: '#{url}'"
        end

        warning do
          services = []
          @conformance.try(:rest)&.each do |endpoint|
            endpoint.try(:security).try(:service)&.each do |sec_service|
              sec_service.try(:coding)&.each do |coding|
                services << coding.code
              end
            end
          end

          assert !services.empty?, 'No security services listed. Conformance/CapabilityStatement.rest.security.service should be SMART-on-FHIR.'
          assert services.any? { |service| service == 'SMART-on-FHIR' }, "Conformance/CapabilityStatement.rest.security.service set to #{services.map { |e| "'" + e + "'" }.join(', ')}.  It should contain 'SMART-on-FHIR'."
        end

        security_extensions =
          @conformance.rest.first.security&.extension
            &.find { |extension| extension.url == SMART_OAUTH_EXTENSION_URL }
            &.extension

        OPTIONAL_OAUTH_ENDPOINTS.each do |endpoint|
          warning do
            url =
              security_extensions
                &.find { |extension| extension.url == endpoint[:url] }
                &.value

            assert url.present?, "No #{endpoint[:description]} endpoint in conformance."
            assert_valid_http_uri url, "Invalid #{endpoint[:description]} url: '#{url}'"
            instance_variable_set(:"@conformance_#{endpoint[:url]}_url", url)
          end
        end

        @instance.update(
          oauth_authorize_endpoint: @conformance_authorize_url,
          oauth_token_endpoint: @conformance_token_url,
          oauth_register_endpoint: @conformance_register_url
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

        (REQUIRED_OAUTH_ENDPOINTS + OPTIONAL_OAUTH_ENDPOINTS).each do |endpoint|
          url = endpoint[:url]
          well_known_url = instance_variable_get(:"@well_known_#{url}_url")
          conformance_url = instance_variable_get(:"@conformance_#{url}_url")

          assert well_known_url == conformance_url, %(
            The #{endpoint[:description]} url is not consistent between the
            well-known configuration and the conformance statement:

            Well-known #{url} url: #{well_known_url}
            Conformance #{url} url: #{conformance_url}
          )
        end
      end
    end
  end
end
