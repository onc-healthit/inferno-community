# frozen_string_literal: true

module Inferno
  module Sequence
    class BulkDataSMARTDiscoverySequence < SequenceBase
      title 'SMART on FHIR Discovery'

      test_id_prefix 'SD'

      requires :url
      defines :oauth_authorize_endpoint, :oauth_token_endpoint, :oauth_register_endpoint

      description 'Retrieve authorization server endpoints for SMART on FHIR'

      details %(
        # Background

        The #{title} Sequence test looks for authorization endpoints as described by the [SMART App Launch Framework](http://hl7.org/fhir/smart-app-launch/conformance/index.html#smart-on-fhir-oauth-authorization-endpoints)
        The SMART launch framework uses OAuth 2.0 to *authorize* apps, like Inferno, to access certain information on a FHIR server.  The authorization service accessed at the endpoint allows
        users to give these apps permission without sharing their credentials with the application itself.  Instead, the application
        receives an access token which allows it to access resources on the server.  The access token itself has a limited lifetime
        and permission scopes associated with it.  A refresh token may also be provided to the application in order to obtain another access token.
        Unlike access tokens, a refresh token is not shared with the resource server.  If OpenID Connect is used, an id token may be provided as well.
        The id token can be used to *authenticate* the user.  The id token is digitally signed and allows the identity of the user to be verified.

        # Test Methodology

        This test suite will access both the `/metadata` and `/.well-known/smart-configuration` endpoints.
        Both endpoints will be checked for:

        * An OAuth 2.0 Authorization endpoint
        * An OAuth 2.0 Token endpoint

        For more information see:

        * [SMART App Launch Framework](http://hl7.org/fhir/smart-app-launch/index.html)
        * [The OAuth 2.0 Authorization Framework](https://tools.ietf.org/html/rfc6749)
        * [OpenID Connect Core](https://openid.net/specs/openid-connect-core-1_0.html)

       )

      def oauth2_metadata_from_conformance
        options = {
          authorize_url: nil,
          token_url: nil
        }
        begin
          @conformance.rest.each do |rest|
            options.merge! oauth2_metadata_from_service_definition(rest)
          end
        rescue StandardError => e
          FHIR.logger.error "Failed to locate SMART-on-FHIR OAuth2 Security Extensions: #{e.message}"
        end
        options.delete_if { |_k, v| v.nil? }
        options.clear if options.keys.size != 1
        options
      end

      def oauth2_metadata_from_service_definition(rest)
        oauth_extension = 'http://fhir-registry.smarthealthit.org/StructureDefinition/oauth-uris'
        token_extension = 'token'
        options = {
          authorize_url: nil,
          token_url: nil
        }
        rest.security.extension.find { |x| x.url == oauth_extension }.extension.each do |ext|
          case ext.url
          when token_extension
            options[:token_url] = ext.value
          when "#{oauth_extension}\##{token_extension}"
            options[:token_url] = ext.value
          end
        end
        options
      end

      test 'Conformance/Capability Statement provides OAuth 2.0 endpoints' do
        metadata do
          id '01'
          link 'http://www.hl7.org/fhir/smart-app-launch/capability-statement/'
          desc %(

           If a server requires SMART on FHIR authorization for access, its metadata must support automated discovery of OAuth2 endpoints

          )
        end

        @conformance = @client.conformance_statement
        oauth_metadata = oauth2_metadata_from_conformance
        assert !oauth_metadata.nil?, 'No OAuth Metadata in Conformance/CapabiliytStatemeent resource'
        @conformance_token_url = oauth_metadata[:token_url]
        assert !@conformance_token_url.blank?, 'No token URI provided in conformance statement.'
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
          assert !registration_url.blank?, 'No dynamic registration endpoint in conformance.'
          assert_valid_http_uri registration_url, "Invalid registration url: '#{registration_url}'"

          manage_url = security_info.extension.find { |x| x.url == 'manage' }
          manage_url = manage_url.value if manage_url
          assert !manage_url.blank?, 'No user-facing authorization management workflow entry point for this FHIR server.'
        end

        @instance.update(oauth_authorize_endpoint: @conformance_authorize_url, oauth_token_endpoint: @conformance_token_url, oauth_register_endpoint: registration_url)
      end
    end
  end
end
