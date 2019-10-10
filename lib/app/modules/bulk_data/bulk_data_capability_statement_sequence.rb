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
        The #{title} Sequence tests a FHIR server's ability to formally describe features supported by the API by
        using the [Capability Statement](https://www.hl7.org/fhir/capabilitystatement.html) resource.
        The features described in the Capability Statement must be consistent with the required capabilities of a
        FHIR server.

        Not all servers are expected to implement all possible queries and data elements described in FHIR
        or by an Implementation Guide.
        The Capability Statement resource allows clients to determine which resources are supported by a FHIR Server.

        Note that the name of this resource changed to from 'Conformance Statement' to 'CapabilityStatement' in STU3
        to better describe the intent of this resource.
        This test refers to it as the Capability Statement.

        This sequence also checks for support for operations defined in the
        [Bulk Data Implementation Guide](https://build.fhir.org/ig/HL7/bulk-data/index.html).

        # Test Methodology

        This test suite accesses the server endpoint at `/metadata` using a `GET` request.
        It parses the Capability Statement and verifies that :

        * The endpoint is secured by an appropriate cryptographic protocol
        * The resource matches the expected FHIR version defined by the tests
        * The resource is a valid FHIR resource
        * The server claims support for JSON encoding of resources

        It collects the following information that is saved in the testing session for use by later tests:

        * List of resources supported
        * List of queries parameters supported

        For more information of the Capability Statement, visit these links:

        * [Capability Statement](https://www.hl7.org/fhir/capabilitystatement.html)
        * [DSTU2 Conformance Statement](https://www.hl7.org/fhir/DSTU2/conformance.html)
      )

      def assert_operation(op_name); end

      test 'FHIR server capability states JSON support' do
        metadata do
          id '04'
          link 'http://hl7.org/fhir/us/core/2019Jan/CapabilityStatement-us-core-server.html'
          description %(

            FHIR provides multiple [representation formats](https://www.hl7.org/fhir/formats.html) for resources, including JSON and XML.
            US Core profiles require servers to use the [JSON representation](https://www.hl7.org/fhir/json.html):

            [```The US Core Server **SHALL** Support json source formats for all US Core interactions.```](https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html)

            The FHIR capability interaction require servers to describe which formats are available for clients to use.
            The server must explicitly state that JSON is supported.  This is located in the
            [format element](https://www.hl7.org/fhir/capabilitystatement-definitions.html#CapabilityStatement.format)
            of the CapabilityStatement Resource.

            This test checks that one of the following values are located in the format field.

            * json
            * application/json
            * application/fhir+json
          )
        end

        assert @conformance.class == versioned_conformance_class, 'Expected valid Conformance resource'
        assert json_formats.any? { |format| @conformance.format.include? format }, 'Conformance does not state support for json.'
      end

      test 'FHIR server capability SHOULD instantiate from CapabilityStatment-bulk-data' do
        metadata do
          id '05'
          link 'https://build.fhir.org/ig/HL7/bulk-data/operations/index.html'
          description %(

            To declare conformance with this IG, a server should include the following URL in its own CapabilityStatement.instantiates:
            http://hl7.org/fhir/uv/bulkdata/CapabilityStatement/bulk-data

          )
          optional
        end

        assert @conformance.instantiates&.include?('http://hl7.org/fhir/uv/bulkdata/CapabilityStatement/bulk-data'), 'CapabilityStatement did not instantiate from "http://www.hl7.org/fhir/bulk-data/CapabilityStatement-bulk-data.html"'
      end

      test 'FHIR server capability SHOULD have export operation' do
        metadata do
          id '06'
          link 'https://build.fhir.org/ig/HL7/bulk-data/operations/index.html'
          description %(

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

      test 'FHIR server capability SHOULD have patient-export operation' do
        metadata do
          id '07'
          link 'https://build.fhir.org/ig/HL7/bulk-data/operations/index.html'
          description %(

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
          description %(

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
