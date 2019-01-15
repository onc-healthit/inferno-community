module Inferno
  module Sequence
    class SMARTDiscoverySequence < SequenceBase

      title 'SMART on FHIR Discovery'

      test_id_prefix 'SD'

      requires :url
      defines :oauth_authorize_endpoint, :oauth_token_endpoint, :oauth_register_endpoint

      description 'Retrieve authorization server endpoints for SMART on FHIR'
      details 'Input Details TODO'

      test 'Retrieve Authorization from Well Known endpoint' do

        metadata {
          id '01'
          optional
          link 'http://www.hl7.org/fhir/smart-app-launch/conformance/#using-well-known'
          desc %(
            The authorization endpoints accepted by a FHIR resource server can be exposed as a Well-Known Uniform Resource Identifier
          )
        }
        
        oauth_configuration_url = @instance.url.chomp('/') + '/.well-known/smart-configuration'
        @oauth_configuration_response = LoggedRestClient.get(oauth_configuration_url)
        assert_response_ok(@oauth_configuration_response)
        @oauth_configuration_response_body =  JSON.parse(@oauth_configuration_response.body)

        assert !@oauth_configuration_response_body.nil?, 'No authorization response body available'
        authorize_url = @oauth_configuration_response_body['authorization_endpoint']
        token_url = @oauth_configuration_response_body['token_endpoint']
        capabilities = @oauth_configuration_response_body['capabilities']

        assert !authorize_url.blank?, 'No authorize URI provided in response.'
        assert !token_url.blank?, 'No token URI provided in response.'
        assert !capabilities.nil?, 'The response did not contain capabilities as required'
        assert capabilities.kind_of?(Array), 'The capabilities response is not an array'

        @instance.update(oauth_authorize_endpoint: authorize_url, oauth_token_endpoint: token_url)

      end

      test 'Conformance Statement provides OAuth 2.0 endpoints' do

        metadata {
          id '02'
          optional
          link 'http://www.hl7.org/fhir/smart-app-launch/capability-statement/'
          desc %(

           If a server requires SMART on FHIR authorization for access, its metadata must support automated discovery of OAuth2 endpoints

          )
        }

        assert @conformance.class == versioned_conformance_class, 'Expected valid Conformance resource'
        oauth_metadata = @client.get_oauth2_metadata_from_conformance(false) # strict mode off, don't require server to state smart conformance
        assert !oauth_metadata.nil?, 'No OAuth Metadata in conformance statement'
        authorize_url = oauth_metadata[:authorize_url]
        token_url = oauth_metadata[:token_url]
        assert !authorize_url.blank?, 'No authorize URI provided in conformance statement.'
        assert (authorize_url =~ /\A#{URI::regexp(['http', 'https'])}\z/) == 0, "Invalid authorize url: '#{authorize_url}'"
        assert !token_url.blank?, 'No token URI provided in conformance statement.'
        assert (token_url =~ /\A#{URI::regexp(['http', 'https'])}\z/) == 0, "Invalid token url: '#{token_url}'"

        warning {
          service = []
          @conformance.try(:rest)&.each do |endpoint|
              endpoint.try(:security).try(:service)&.each do |sec_service|
                sec_service.try(:coding)&.each do |coding|
                  service << coding.code
                end
              end
            end

          assert !service.empty?, 'No security services listed. Conformance.rest.security.service should be SMART-on-FHIR.'
          assert service.any? {|any_service| any_service == 'SMART-on-FHIR'}, "Conformance.rest.security.service set to #{service.map{ |e| "'" + e + "'" }.join(', ')}.  It should contain 'SMART-on-FHIR'."
        }

        registration_url = nil

        warning {
          security_info = @conformance.rest.first.security.extension.find{|x| x.url == 'http://fhir-registry.smarthealthit.org/StructureDefinition/oauth-uris' }
          registration_url = security_info.extension.find{|x| x.url == 'register'}
          registration_url = registration_url.value if registration_url
          assert !registration_url.blank?,  'No dynamic registration endpoint in conformance.'
          assert (registration_url =~ /\A#{URI::regexp(['http', 'https'])}\z/) == 0, "Invalid registration url: '#{registration_url}'"

          manage_url = security_info.extension.find{|x| x.url == 'manage'}
          manage_url = manage_url.value if manage_url
          assert !manage_url.blank?,  'No user-facing authorization management workflow entry point for this FHIR server.'
        }

        @instance.update(oauth_authorize_endpoint: authorize_url, oauth_token_endpoint: token_url, oauth_register_endpoint: registration_url)
      end

      test 'OAuth Endpoints must be either in conformance statement or well known endpoint' do

        metadata {
          id '03'
          link 'http://www.hl7.org/fhir/smart-app-launch/capability-statement/'
          desc %(

           If a server requires SMART on FHIR authorization for access, its metadata must support automated discovery of OAuth2 endpoints

          )
        }

        # the two above tests are optional
        # we need to have it be at least one
        # so see if what we saved at the instance.oauth_authorize_endpoitn and oauth_token_endpoint is not empty. etc.
        # fail if empty assert !@instance.adsfasdfasdf.nil?
        
      end




      def versioned_conformance_class
        if @instance.fhir_version == 'dstu2'
          FHIR::DSTU2::Conformance
        elsif @instance.fhir_version == 'stu3'
          FHIR::CapabilityStatement
        end
      end

    end
  end
end
