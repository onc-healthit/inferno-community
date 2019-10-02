# frozen_string_literal: true

require_relative '../core/capability_statement_sequence'

module Inferno
  module Sequence
    class BulkDataCapabilityStatementSequence < CapabilityStatementSequence
      extends_sequence CapabilityStatementSequence

      title 'Capability Statement'

      test_id_prefix 'C'

      requires :url
      defines :oauth_authorize_endpoint, :oauth_token_endpoint, :oauth_register_endpoint

      description 'Retrieve information about supported server functionality in the Capability Statement.'
      details %(
        # Background
         The #{title} Sequence tests a FHIR server's ability to formally describe features
        supported by the API by using the [Capability Statement](https://www.hl7.org/fhir/capabilitystatement.html) resource.
        The features described in the Capability Statement must be consistent with the required capabilities of an
        Argonaut server.  The Capability Statement must also advertise the location of the required SMART on FHIR endpoints
        that enable authenticated access to the FHIR server resources.

        Not all servers are expected to implement all possible queries and data elements described in the Argonaut API.
        For example, the Argonaut specification requires that the Patient resource and only one other Argonaut resource are required.
        Implementing the Capability Statement resource allows clients to dynamically determine which of these resources
        are supported at runtime, instead of having to specifically write the application to accomidate every known server implementation
        at development time.  Similarly, by providing information about the location of SMART on FHIR OAuth 2.0 endpoints,
        the client does not have to be hard-coded with information about the authorization services associated with
        every FHIR API.

        Note that the name of this resource changed to 'Capability Statement' in STU3 to better describe the intent of this resource.
        This test refers to it as the Capability Statement as that is what it was called in DSTU2.

        # Test Methodology

        This test suite accesses the server endpoint at `/metadata` using a `GET` request.  It parses the Capability Statement and
        verifies that the server claims support of following features:

        * JSON encoding of resources
        * Patient resource
        * At least one of the other resources that form the basis of Argonaut profiles
        * SMART on FHIR authorization

        It collects the following information that is saved in the testing session for use by later tests:

        * List of resources supported
        * List of queries parameters supported
        * SMART on FHIR endpoints

        For more information of the Capability Statement, visit these links:

        * [Capability](https://www.hl7.org/fhir/capabilitystatement.html)
        * [Argonaut Capability Requirements](http://hl7.org/fhir/us/core/2019Jan/CapabilityStatement-us-core-server.html)
        * [SMART on FHIR Conformance](http://hl7.org/fhir/smart-app-launch/conformance/index.html)
      )

      def assert_operation(op_name); end

      test 'FHIR server capability states JSON support' do
        metadata do
          id '04'
          link 'http://hl7.org/fhir/us/core/2019Jan/CapabilityStatement-us-core-server.html'
          desc %(

            FHIR provides multiple [representation formats](https://www.hl7.org/fhir/DSTU2/formats.html) for resources, including JSON and XML.
            Argonaut profiles require servers to use the JSON representation:

            ```
            The Argonaut Data Query Server shall support JSON resource format for all Argonaut Data Query interactions.
            ```
            [http://hl7.org/fhir/us/core/2019Jan/CapabilityStatement-us-core-server.html](http://hl7.org/fhir/us/core/2019Jan/CapabilityStatement-us-core-server.html)

            The FHIR capability interaction require servers to describe which formats are available for clients to use.  The server must
            explicitly state that JSON is supported. This is located in the [format element](https://www.hl7.org/fhir/capabilitystatement-definitions.html#CapabilityStatement.format)
            of the Capability Resource.

            This test checks that one of the following values are located in the [format field](https://www.hl7.org/fhir/DSTU2/json.html).

            * json
            * application/json
            * application/json+fhir

            Note that FHIR changed the FHIR-specific JSON mime type to `application/fhir+json` in later versions of the specification.

          )
        end

        assert @conformance.class == versioned_conformance_class, 'Expected valid Conformance resource'
        formats = ['json', 'applcation/json', 'application/json+fhir', 'application/fhir+json']
        assert formats.any? { |format| @conformance.format.include? format }, 'Conformance does not state support for json.'
      end

      test 'FHIR server capability SHOULD instantiate from CapabilityStatment-bulk-data' do
        metadata do
          id '05'
          link 'https://build.fhir.org/ig/HL7/bulk-data/operations/index.html'
          desc %(

            To declare conformance with this IG, a server should include the following URL in its own CapabilityStatement.instantiates:
            http://www.hl7.org/fhir/bulk-data/CapabilityStatement-bulk-data.html

          )
          optional
        end

        assert @conformance.instantiates&.include?('http://www.hl7.org/fhir/bulk-data/CapabilityStatement-bulk-data.html'), 'CapabilityStatement did not instantiate from "http://www.hl7.org/fhir/bulk-data/CapabilityStatement-bulk-data.html"'
      end

      test 'FHIR server capability SHOULD have export operation' do
        metadata do
          id '06'
          link 'https://build.fhir.org/ig/HL7/bulk-data/operations/index.html'
          desc %(

            These OperationDefinitions have been defined for this implementation guide.
              * Export: export any data from a FHIR server
              * Patient Export: export patient data from a FHIR server
              * Group Export: export data for groups of patients from a FHIR server

          )
          optional
        end

        begin
          Inferno::Models::ServerCapabilities.create(
            testing_instance_id: @instance.id,
            capabilities: @conformance.as_json
          )
        rescue StandardError
          assert false, 'Capability Statement could not be parsed.'
        end

        assert_operation_supported(@instance.server_capabilities, 'export')
      end

      test 'FHIR server capability SHOULD have export operation' do
        metadata do
          id '07'
          link 'https://build.fhir.org/ig/HL7/bulk-data/operations/index.html'
          desc %(

            These OperationDefinitions have been defined for this implementation guide.
              * Export: export any data from a FHIR server
              * Patient Export: export patient data from a FHIR server
              * Group Export: export data for groups of patients from a FHIR server

          )
          optional
        end

        assert_operation_supported(@instance.server_capabilities, 'patient-export')
      end

      test 'FHIR server capability SHOULD have group-export operation' do
        metadata do
          id '08'
          link 'https://build.fhir.org/ig/HL7/bulk-data/operations/index.html'
          desc %(

            These OperationDefinitions have been defined for this implementation guide.
              * Export: export any data from a FHIR server
              * Patient Export: export patient data from a FHIR server
              * Group Export: export data for groups of patients from a FHIR server

          )
          optional
        end

        assert_operation_supported(@instance.server_capabilities, 'group-export')
      end
    end
  end
end
