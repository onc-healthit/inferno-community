# frozen_string_literal: true

module Inferno
  module Sequence
    class BulkDataDiscoverySequence < SequenceBase
      title 'Bulk Data Discovery'

      test_id_prefix 'BDD'

      requires :url
      defines :bulk_token_endpoint, :oauth_register_endpoint

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

      attr_accessor :well_known_configuration, :conformance

      def oauth2_metadata_from_conformance
        options = {}
        begin
          @conformance.rest.each do |rest|
            options.merge! @client.get_oauth2_metadata_from_service_definition(rest)
          end
        rescue StandardError => e
          FHIR.logger.error "Failed to locate SMART-on-FHIR OAuth2 Security Extensions: #{e.message}"
        end

        options.compact
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
        @instance.update(
          bulk_token_endpoint: @well_known_configuration['token_endpoint'],
          oauth_register_endpoint: @well_known_configuration['registration_endpoint']
        )
      end

      test :validate_well_known_configuration do
        metadata do
          id '02'
          name 'Well-Known Configuration contains required fields'
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

      test :read_conformance_oauth_endpoins do
        metadata do
          id '03'
          name 'Conformance/Capability Statement provides OAuth 2.0 endpoints'
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

        conformance_token_url = oauth_metadata[:token_url]

        assert conformance_token_url.present?, 'No token URI provided in Conformance/CapabilityStatement resource'
        assert_valid_http_uri conformance_token_url, "Invalid token url: '#{conformance_token_url}'"

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
          bulk_token_endpoint: conformance_token_url
        )
      end
    end
  end
end
