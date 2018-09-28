module Inferno
  module Sequence
    class ConformanceSequence < SequenceBase

      title 'Conformance Statement'

      test_id_prefix 'C'

      requires :url
      defines :oauth_authorize_endpoint, :oauth_token_endpoint, :oauth_register_endpoint

      description 'Retrieve information about supported server functionality in the Conformance Statement.'
      details %(
        # Background
         The #{title} Sequence tests a FHIR server's ability to formally describe features
        supported by the API by using the [Conformance Statement](https://www.hl7.org/fhir/DSTU2/conformance.html) resource.
        The features described in the Conformance Statement must be consistent with the required capabilities of an
        Argonaut server.  The Conformance Statement must also advertise the location of the required SMART on FHIR endpoints
        that enable authenticated access to the FHIR server resources.

        Not all servers are expected to implement all possible queries and data elements described in the Argonaut API.
        For example, the Argonaut specification requires that the Patient resource and only one other Argonaut resource are required.
        Implementing the Conformance Statement resource allows clients to dynamically determine which of these resources
        are supported at runtime, instead of having to specifically write the application to accomidate every known server implementation
        at development time.  Similarly, by providing information about the location of SMART on FHIR OAuth 2.0 endpoints,
        the client does not have to be hard-coded with information about the authorization services associated with
        every FHIR API.

        Note that the name of this resource changed to 'Capability Statement' in STU3 to better describe the intent of this resource.
        This test refers to it as the Capability Statement as that is what it was called in DSTU2.

        # Test Methodology

        This test suite accesses the server endpoint at `/metadata` using a `GET` request.  It parses the Conformance Statement and
        verifies that the server claims support of following features:

        * JSON encoding of resources
        * Patient resource
        * At least one of the other resources that form the basis of Argonaut profiles
        * SMART on FHIR authorization

        It collects the following information that is saved in the testing session for use by later tests:

        * List of resources supported
        * List of queries parameters supported
        * SMART on FHIR endpoints

        For more information of the Conformance Statement, visit these links:

        * Conformance
        * Argonaut Conformance Requirements
        * SMART on FHIR Conformance
      )

      test 'FHIR server secured by transport layer security' do

        metadata {
          id '01'
          link 'https://www.hl7.org/fhir/security.html'
          optional
          desc %(
            All exchange of production data should be secured with TLS/SSL v1.2.
          )
        }

        if @disable_tls_tests
          skip 'TLS tests have been disabled by configuration.', %(

               Inferno allows users to disable TLS testing if they are using a network configuration
               that prevents TLS from tested properly.
            )

        end

        assert_tls_1_2 @instance.url

        warning {
          assert_deny_previous_tls @instance.url
        }
      end

      test 'FHIR server supports the conformance interaction that defines how it supports resources' do

        metadata {
          id '02'
          link 'http://hl7.org/fhir/DSTU2/http.html#conformance'
          desc %(
            The conformance 'whole system' interaction provides a method to get the conformance statement for
            the FHIR server.  This test checks that the server responds to a `GET` request at the following endpoint:

            ```
            GET [base]/metadata
            ```

            This test checks the following SHALL requirement for DSTU2 FHIR:

            > Applications SHALL return a Conformance Resource that specifies which resource types and interactions are supported for the GET command

            [http://hl7.org/fhir/DSTU2/http.html#conformance](http://hl7.org/fhir/DSTU2/http.html#conformance)

            It does this by checking that the server responds with an HTTP OK 200 status code and that the body of the
            response contains a valid [DSTU2 Conformance resource](http://hl7.org/fhir/DSTU2/conformance.html).
            This test does not inspect the content of the Conformance resource to see if it contains the required information.
            It only checks to see if the RESTful interaction is supported and returns a valid Conformance resource.

            This test does not check to see if the server supports the `OPTION` command, though DSTU2 provides
            this as a second method to retrieve the Conformance for the server.  It is not expected that clients
            will broadly support this method, so this test does not cover this option.
          )
        }

        @client.set_no_auth
        @conformance = @client.conformance_statement(FHIR::Formats::ResourceFormat::RESOURCE_JSON_DSTU2)
        assert_response_ok @client.reply, %(

        )
        assert @conformance.class == FHIR::DSTU2::Conformance, 'Expected valid DSTU2 Conformance resource.'
      end

      test 'FHIR server conformance states JSON support' do

        metadata {
          id '03'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(

            FHIR provides multiple (https://www.hl7.org/fhir/DSTU2/formats.html)[representation formats] for resources, including JSON and XML.
            Argonaut profiles require servers to use the JSON representation:

            ```
            The Argonaut Data Query Server shall support JSON resource format for all Argonaut Data Query interactions.
            ```
            [http://www.fhir.org/guides/argonaut/r2/Conformance-server.html](http://www.fhir.org/guides/argonaut/r2/Conformance-server.html)

            The FHIR conformance interaction require servers to describe which formats are available for clients to use.  The server must
            explicitly state that JSON is supported. This is located in the (format element)[https://www.hl7.org/fhir/DSTU2/conformance-definitions.html#Conformance.format]
            of the Conformance Resource.

            This test checks that one of the following values are located in the format field.

            * json
            * application/json
            * application/json+fhir

            Note that FHIR changed the FHIR-specific JSON mime type to `application/fhir+json` in later versions of the specification.

          )
        }

        assert @conformance.class == FHIR::DSTU2::Conformance, 'Expected valid DSTU2 Conformance resource'
        assert @conformance.format.include?('json') || @conformance.format.include?('application/json+fhir'), 'Conformance does not state support for json.'
      end

      test 'Conformance Statement provides OAuth 2.0 endpoints' do

        metadata {
          id '04'
          link 'http://www.hl7.org/fhir/smart-app-launch/capability-statement/'
          desc %(

           If a server requires SMART on FHIR authorization for access, its metadata must support automated discovery of OAuth2 endpoints

          )
        }

        assert @conformance.class == FHIR::DSTU2::Conformance, 'Expected valid DSTU2 Conformance resource'
        oauth_metadata = @client.get_oauth2_metadata_from_conformance(false) # strict mode off, don't require server to state smart conformance
        assert !oauth_metadata.nil?, 'No OAuth Metadata in conformance statement'
        authorize_url = oauth_metadata[:authorize_url]
        token_url = oauth_metadata[:token_url]
        assert !authorize_url.blank?, 'No authorize URI provided in conformance statement.'
        assert (authorize_url =~ /\A#{URI::regexp(['http', 'https'])}\z/) == 0, "Invalid authorize url: '#{authorize_url}'"
        assert !token_url.blank?, 'No token URI provided in conformance statement.'
        assert (token_url =~ /\A#{URI::regexp(['http', 'https'])}\z/) == 0, "Invalid token url: '#{token_url}'"

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

      test 'Conformance Statement describes SMART on FHIR core capabilities' do

        metadata {
          id '05'
          link 'http://www.hl7.org/fhir/smart-app-launch/conformance/'
          optional
          desc %(

           A SMART on FHIR server can convey its capabilities to app developers by listing a set of the capabilities.

          )
        }

        required_capabilities = ['launch-ehr',
                                 'launch-standalone',
                                 'client-public',
                                 'client-confidential-symmetric',
                                 'sso-openid-connect',
                                 'context-ehr-patient',
                                 'context-standalone-patient',
                                 'context-standalone-encounter',
                                 'permission-offline',
                                 'permission-patient',
                                 'permission-user'
        ]

        assert @conformance.class == FHIR::DSTU2::Conformance, 'Expected valid DSTU2 Conformance resource'
        extensions = @conformance.try(:rest).try(:first).try(:security).try(:extension)
        assert !extensions.nil?, 'No SMART capabilities listed in conformance.'
        capabilities = extensions.select{|x| x.url == 'http://fhir-registry.smarthealthit.org/StructureDefinition/capabilities' }
        assert !capabilities.nil?, 'No SMART capabilities listed in conformance.'
        available_capabilities = capabilities.map{ |v| v.valueCode}
        missing_capabilities = (required_capabilities - available_capabilities)
        assert missing_capabilities.empty?, "Conformance statement does not list required SMART capabilties: #{missing_capabilities.join(', ')}"
      end

      test 'Conformance Statement lists supported Argonaut profiles, operations and search parameters' do

        metadata {
          id '06'
          link 'http://www.hl7.org/fhir/smart-app-launch/conformance/'
          desc %(
           The Argonaut Data Query Server shall declare a Conformance identifying the list of profiles, operations, search parameter supported.

          )
        }

        assert @conformance.class == FHIR::DSTU2::Conformance, 'Expected valid DSTU2 Conformance resource'

        begin
          @instance.save_supported_resources(@conformance)
        rescue => e
          assert false, 'Conformance Statement could not be parsed.'
        end

        assert @instance.conformance_supported?(:Patient, [:read]), 'Patient resource with read interaction is not listed in conformance statement.'

      end

    end

  end
end
