# frozen_string_literal: true

module Inferno
  module Sequence
    class BulkDataDiscoverySequence < SequenceBase
      title 'Bulk Data Discovery'

      test_id_prefix 'Discovery'

      requires :url
      defines :oauth_authorize_endpoint, :oauth_token_endpoint, :oauth_register_endpoint

      description "Retrieve server's SMART on FHIR configuration"

      details %(
        # Background

        The #{title} Sequence test looks for authorization endpoints and SMART
        capabilities as described by the [SMART Backend Services: Authorization
        Guide](https://build.fhir.org/ig/HL7/bulk-data/authorization/index.html).
      )

      WELL_KNOWN_FIELDS = [
        'token_endpoint',
        'scopes_supported',
        'token_endpoint_auth_methods_supported',
        'token_endpoint_auth_signing_alg_values_supported'
      ].freeze

      SMART_OAUTH_EXTENSION_URL = 'http://fhir-registry.smarthealthit.org/StructureDefinition/oauth-uris'

      REQUIRED_OAUTH_ENDPOINTS = [
        { url: 'token', description: 'token' }
      ].freeze

      def oauth2_metadata_from_conformance
        options = {
          token_url: nil
        }
        begin
          @conformance.rest.each do |rest|
            options.merge! @client.get_oauth2_metadata_from_service_definition(rest)
          end
        rescue StandardError => e
          FHIR.logger.error "Failed to locate SMART-on-FHIR OAuth2 Security Extensions: #{e.message}"
        end

        options.delete_if { |_k, v| v.nil? }
        options
      end

      test :read_well_known_endpoint do
        metadata do
          id '01'
          name 'Retrieve Configuration from well-known endpoint'
          link 'http://www.hl7.org/fhir/smart-app-launch/conformance/#using-well-known'
          description %(
            The authorization endpoints accepted by a FHIR resource server can
            be exposed as a Well-Known Uniform Resource Identifier
          )
          optional
        end

        well_known_configuration_url = @instance.url.chomp('/') + '/.well-known/smart-configuration'
        well_known_configuration_response = LoggedRestClient.get(well_known_configuration_url)
        assert_response_ok(well_known_configuration_response)
        assert_response_content_type(well_known_configuration_response, 'application/json')
        assert_valid_json(well_known_configuration_response.body)

        @well_known_configuration = JSON.parse(well_known_configuration_response.body)
        @well_known_token_url = @well_known_configuration['token_endpoint']
        @well_known_register_url = @well_known_configuration['registration_endpoint']
        @well_known_token_auth_methods = @well_known_configuration['token_endpoint_auth_methods_supported']
        @well_known_token_auth_signings = @well_known_configuration['token_endpoint_auth_signing_alg_values_supported']
        @well_known_scopes = @well_known_configuration['scopes_supported']

        @instance.update(
          oauth_token_endpoint: @well_known_token_url,
          oauth_register_endpoint: @well_known_register_url
        )

        assert @well_known_configuration.present?, 'No .well-known/smart-configuration body'
      end

      test 'Configuration from well-known endpoint contains required fields' do
        metadata do
          id '02'
          link 'https://build.fhir.org/ig/HL7/bulk-data/authorization/index.html#advertising-server-conformance-with-smart-backend-services'
          description %(
            The JSON from .well-known/smart-configuration contains the following
            required fields: #{WELL_KNOWN_FIELDS.map { |field| "`#{field}`" }.join(', ')}
          )
          optional
        end

        skip 'Server does NOT provide .well-known endpoint' unless @well_known_configuration.present?

        missing_fields = WELL_KNOWN_FIELDS - @well_known_configuration.keys
        assert missing_fields.empty?, "The following required fields are missing: #{missing_fields.join(', ')}"
      end

      test 'Conformance/Capability Statement provides OAuth 2.0 endpoints' do
        metadata do
          id '03'
          link 'http://hl7.org/fhir/smart-app-launch/conformance/index.html#using-cs'
          description %(
            If a server requires SMART on FHIR authorization for access, its
            metadata must support automated discovery of OAuth2 endpoints.
          )
          optional
        end

        @conformance = @client.conformance_statement
        oauth_metadata = oauth2_metadata_from_conformance

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

        @instance.update(
          oauth_token_endpoint: @conformance_token_url
        )
      end

      # test 'OAuth Endpoints must be the same in the conformance statement and well known endpoint' do
      #   metadata do
      #     id '05'
      #     link 'http://hl7.org/fhir/smart-app-launch/conformance/index.html#using-cs'
      #     description %(
      #      If a server requires SMART on FHIR authorization for access, its
      #      metadata must support automated discovery of OAuth2 endpoints.
      #     )
      #   end

      #   (REQUIRED_OAUTH_ENDPOINTS + OPTIONAL_OAUTH_ENDPOINTS).each do |endpoint|
      #     url = endpoint[:url]
      #     well_known_url = instance_variable_get(:"@well_known_#{url}_url")
      #     conformance_url = instance_variable_get(:"@conformance_#{url}_url")

      #     assert well_known_url == conformance_url, %(
      #       The #{endpoint[:description]} url is not consistent between the
      #       well-known configuration and the conformance statement:

      #       Well-known #{url} url: #{well_known_url}
      #       Conformance #{url} url: #{conformance_url}
      #     )
      #   end
      # end
    end
  end
end
