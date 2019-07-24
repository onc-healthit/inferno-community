# frozen_string_literal: true

module Inferno
  module Sequence
    class CapabilityStatementSequence < SequenceBase
      title 'Capability Statement'

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
        are supported at runtime, instead of having to specifically write the application to accommodate every known server implementation
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

        * [Conformance](https://www.hl7.org/fhir/DSTU2/conformance.html)
        * [Argonaut Conformance Requirements for Servers](https://www.fhir.org/guides/argonaut/r2/Conformance-server.html)
        * [SMART on FHIR Conformance](http://hl7.org/fhir/smart-app-launch/conformance/index.html)
      )

      test 'FHIR server secured by transport layer security' do
        metadata do
          id '01'
          link 'https://www.hl7.org/fhir/security.html'
          desc %(
            All exchange of production data should be secured with TLS/SSL v1.2.
          )
        end

        omit_if_tls_disabled

        assert_tls_1_2 @instance.url

        warning do
          assert_deny_previous_tls @instance.url
        end
      end

      test 'FHIR version of the server matches the FHIR version expected by tests' do
        metadata do
          id '02'
          link 'http://www.hl7.org/fhir/directory.cfml'
          desc %(
            Checks that the FHIR version of the server matches the FHIR version expected by the tests.
            This test will inspect the CapabilityStatement returned by the server to verify the FHIR version of the server.
          )
        end

        pass 'Tests are not version dependent' if @instance.fhir_version.blank?

        # @client.detect_version is a symbol
        assert_equal(@instance.fhir_version.upcase, @client.detect_version.to_s.upcase, 'FHIR client version does not match with instance version.')
      end

      test 'FHIR server supports the conformance interaction that defines how it supports resources' do
        metadata do
          id '03'
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
        end

        @client.set_no_auth
        @conformance = @client.conformance_statement
        assert_response_ok @client.reply

        assert @conformance.class == versioned_conformance_class, 'Expected valid Conformance resource.'
      end
    end
  end
end
