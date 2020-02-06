# frozen_string_literal: true

module Inferno
  module Sequence
    class CapabilityStatementSequence < SequenceBase
      # The acceptable MIME-types for JSON
      # https://www.hl7.org/fhir/json.html
      def json_formats
        ['json', 'application/json', 'application/fhir+json']
      end

      title 'Capability Statement'

      test_id_prefix 'C'

      requires :url
      defines :oauth_authorize_endpoint, :oauth_token_endpoint, :oauth_register_endpoint

      description 'Retrieve information about supported server functionality in the Conformance Statement.'
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

        # Test Methodology

        This test suite accesses the server endpoint at `/metadata` using a `GET` request.
        It parses the Capability Statement and verifies that :

        * The endpoint is secured by an appropriate cryptographic protocol
        * The resource matches the expected FHIR version defined by the tests
        * The resource is a valid FHIR resource

        It collects the following information that is saved in the testing session for use by later tests:

        * List of resources supported
        * List of queries parameters supported

        For more information of the Capability Statement, visit these links:

        * [Capability Statement](https://www.hl7.org/fhir/capabilitystatement.html)
        * [DSTU2 Conformance Statement](https://www.hl7.org/fhir/DSTU2/conformance.html)
      )

      test 'FHIR server secured by transport layer security' do
        metadata do
          id '01'
          link 'https://www.hl7.org/fhir/security.html'
          description %(
            All exchange of production data should be secured with TLS/SSL v1.2.
          )
        end

        omit_if_tls_disabled

        assert_tls_1_2 @instance.url

        warning do
          assert_deny_previous_tls @instance.url
        end
      end

      test 'FHIR server supports the conformance interaction' do
        metadata do
          id '02'
          link 'http://hl7.org/fhir/DSTU2/http.html#conformance'
          description %(
            The conformance 'whole system' interaction provides a method to get the conformance statement for
            the FHIR server.  This test checks that the server responds to a `GET` request at the following endpoint:

            ```
            GET [base]/metadata
            ```

            This test checks the following SHALL requirement for DSTU2 FHIR:

            > Applications SHALL return a Conformance Resource that specifies which resource types and interactions are supported for the GET command

            [http://hl7.org/fhir/DSTU2/http.html#conformance](http://hl7.org/fhir/DSTU2/http.html#conformance)

            for STU3 FHIR:

            >  Applications SHALL return a Capability Statement that specifies which resource types and interactions are supported for the GET command.

            [http://hl7.org/fhir/STU3/http.html#capabilities](http://hl7.org/fhir/STU3/http.html#capabilities)

            or for R4 FHIR:

            > Applications SHALL return a resource that describes the functionality of the server end-point.

            [http://hl7.org/fhir/R4/http.html#capabilities](http://hl7.org/fhir/R4/http.html#capabilities)

            It does this by checking that the server responds with an HTTP OK 200 status code and that the body of the
            response contains a valid [DSTU2 Conformance resource](http://hl7.org/fhir/DSTU2/conformance.html),
            [STU3 CapabilityStatement resource](http://hl7.org/fhir/STU3/capabilitystatement.html), or
            [R4 CapabilityStatement resource](http://hl7.org/fhir/R4/capabilitystatement.html).
            This test does not inspect the content of the Conformance resource to see if it contains the required information.
            It only checks to see if the RESTful interaction is supported and returns a valid Conformance resource.

            This test does not check to see if the server supports the `OPTION` command, though DSTU2 provides
            this as a second method to retrieve the Conformance for the server.  It is not expected that clients
            will broadly support this method, so this test does not cover this option.
          )
        end

        @client.set_no_auth
        @conformance = @client.conformance_statement
        assert_response_ok @client.reply

        assert_valid_conformance

        begin
          @server_capabilities = Inferno::Models::ServerCapabilities.create(
            testing_instance_id: @instance.id,
            capabilities: @conformance.as_json
          )
        rescue StandardError
          assert false, 'Capability Statement could not be parsed.'
        end

        issues = Inferno::RESOURCE_VALIDATOR.validate(@conformance, versioned_resource_class)
        errors = issues[:errors]
        assert errors.blank?, "Invalid #{versioned_conformance_class.name.demodulize}: #{errors.join(', ')}"
      end

      test 'FHIR version of the server matches the FHIR version expected by tests' do
        metadata do
          id '03'
          link 'http://www.hl7.org/fhir/directory.cfml'
          description %(
            Checks that the FHIR version of the server matches the FHIR version expected by the tests.
            This test will inspect the CapabilityStatement returned by the server to verify the FHIR version of the server.
          )
        end

        pass 'Tests are not version dependent' if @instance.fhir_version.blank?

        # @client.detect_version is a symbol
        assert_equal(@instance.fhir_version.upcase, @client.detect_version.to_s.upcase, 'FHIR client version does not match with instance version.')
      end
    end
  end
end
