# frozen_string_literal: true

require_relative '../core/capability_statement_sequence'

module Inferno
  module Sequence
    class USCoreR4CapabilityStatementSequence < CapabilityStatementSequence
      extends_sequence CapabilityStatementSequence

      title 'Conformance Statement'

      test_id_prefix 'R4C'

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
        This test refers to it as the Conformance Statement as that is what it was called in DSTU2.

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

        * [Conformance](http://hl7.org/fhir/conformance-module.html)
        * [Argonaut Conformance Requirements](https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html)
        * [SMART on FHIR Conformance](http://hl7.org/fhir/smart-app-launch/conformance/index.html)
      )

      test 'FHIR server conformance states JSON support' do
        metadata do
          id '03'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(

            FHIR provides multiple [representation formats](https://www.hl7.org/fhir/DSTU2/formats.html) for resources, including JSON and XML.
            Argonaut profiles require servers to use the JSON representation:

            ```
            The Argonaut Data Query Server shall support JSON resource format for all Argonaut Data Query interactions.
            ```
            [http://www.fhir.org/guides/argonaut/r2/Conformance-server.html](http://www.fhir.org/guides/argonaut/r2/Conformance-server.html)

            The FHIR conformance interaction require servers to describe which formats are available for clients to use.  The server must
            explicitly state that JSON is supported. This is located in the [format element](https://www.hl7.org/fhir/DSTU2/conformance-definitions.html#Conformance.format)
            of the Conformance Resource.

            This test checks that one of the following values are located in the [format field](https://www.hl7.org/fhir/DSTU2/json.html).

            * json
            * application/json
            * application/json+fhir

            Note that FHIR changed the FHIR-specific JSON mime type to `application/fhir+json` in later versions of the specification.

          )
        end

        assert @conformance.class == versioned_conformance_class, 'Expected valid Conformance resource'
        assert @conformance.format.include?('json') || @conformance.format.include?('application/json') || @conformance.format.include?('application/json+fhir') || @conformance.format.include?('application/fhir+json'), 'Conformance does not state support for json.'
      end

      test 'Conformance Statement describes SMART on FHIR core capabilities' do
        metadata do
          id '04'
          link 'http://www.hl7.org/fhir/smart-app-launch/conformance/'
          optional
          desc %(

           A SMART on FHIR server can convey its capabilities to app developers by listing a set of the capabilities.

          )
        end

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
                                 'permission-user']

        assert @conformance.class == versioned_conformance_class, 'Expected valid Conformance resource'

        extensions = @conformance.try(:rest).try(:first).try(:security).try(:extension)
        assert !extensions.nil?, 'No SMART capabilities listed in conformance.'
        capabilities = extensions.select { |x| x.url == 'http://fhir-registry.smarthealthit.org/StructureDefinition/capabilities' }
        assert !capabilities.nil?, 'No SMART capabilities listed in conformance.'
        available_capabilities = capabilities.map(&:valueCode)
        missing_capabilities = (required_capabilities - available_capabilities)
        assert missing_capabilities.empty?, "Conformance statement does not list required SMART capabilties: #{missing_capabilities.join(', ')}"
      end

      test 'Conformance Statement lists supported Argonaut profiles, operations and search parameters' do
        metadata do
          id '05'
          link 'https://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
           The Argonaut Data Query Implementation Guide states:

           ```
           The Argonaut Data Query Server SHALL... Declare a Conformance identifying the list of profiles, operations, search parameter supported.
           ```

          )
        end

        assert @conformance.class == versioned_conformance_class, 'Expected valid Conformance resource'

        begin
          @instance.save_supported_resources(@conformance)
        rescue StandardError => e
          assert false, 'Conformance Statement could not be parsed.'
        end

        assert @instance.conformance_supported?(:Patient, [:read]), 'Patient resource with read interaction is not listed in conformance statement.'
      end
    end
  end
end
