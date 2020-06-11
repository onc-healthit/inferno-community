# frozen_string_literal: true

module Inferno
  module Sequence
    class UsCoreR4CapabilityStatementSequence < SequenceBase
      # The acceptable MIME-types for JSON
      # https://www.hl7.org/fhir/json.html
      def json_formats
        ['json', 'application/json', 'application/fhir+json']
      end

      title 'Capability Statement'

      test_id_prefix 'USCCAP'

      requires :url
      defines :oauth_authorize_endpoint, :oauth_token_endpoint, :oauth_register_endpoint

      description 'Retrieve information about supported server functionality in the Capability Statement.'
      details %(
        # Background
        The #{title} Sequence tests a FHIR server's ability to formally describe
        features supported by the API by using the [Capability
        Statement](https://www.hl7.org/fhir/capabilitystatement.html) resource.
        The features described in the Capability Statement must be consistent
        with the required capabilities of a US Core server. The Capability
        Statement must also advertise the location of the required SMART on FHIR
        endpoints that enable authenticated access to the FHIR server resources.

        The Capability Statement resource allows clients to determine which
        resources are supported by a FHIR Server. Not all servers are expected
        to implement all possible queries and data elements described in the US
        Core API. For example, the US Core Implementation Guide requires that
        the Patient resource and only one additional resource profile from the
        US Core Profiles.


        # Test Methodology

        This test suite accesses the server endpoint at `/metadata` using a
        `GET` request. It parses the Capability Statement and verifies that:

        * The endpoint is secured by an appropriate cryptographic protocol
        * The resource matches the expected FHIR version defined by the tests
        * The resource is a valid FHIR resource
        * The server claims support for JSON encoding of resources
        * The server claims support for the Patient resource and one other
          resource

        It collects the following information that is saved in the testing
        session for use by later tests:

        * List of resources supported
        * List of queries parameters supported
      )

      PROFILES = {
        'AllergyIntolerance' => ['http://hl7.org/fhir/us/core/StructureDefinition/us-core-allergyintolerance'],
        'CarePlan' => ['http://hl7.org/fhir/us/core/StructureDefinition/us-core-careplan'],
        'CareTeam' => ['http://hl7.org/fhir/us/core/StructureDefinition/us-core-careteam'],
        'Condition' => ['http://hl7.org/fhir/us/core/StructureDefinition/us-core-condition'],
        'Device' => ['http://hl7.org/fhir/us/core/StructureDefinition/us-core-implantable-device'],
        'DiagnosticReport' => [
          'http://hl7.org/fhir/us/core/StructureDefinition/us-core-diagnosticreport-lab',
          'http://hl7.org/fhir/us/core/StructureDefinition/us-core-diagnosticreport-note'
        ],
        'DocumentReference' => ['http://hl7.org/fhir/us/core/StructureDefinition/us-core-documentreference'],
        'Encounter' => ['http://hl7.org/fhir/us/core/StructureDefinition/us-core-encounter'],
        'Goal' => ['http://hl7.org/fhir/us/core/StructureDefinition/us-core-goal'],
        'Immunization' => ['http://hl7.org/fhir/us/core/StructureDefinition/us-core-immunization'],
        'Location' => ['http://hl7.org/fhir/us/core/StructureDefinition/us-core-location'],
        'Medication' => ['http://hl7.org/fhir/us/core/StructureDefinition/us-core-medication'],
        'MedicationRequest' => ['http://hl7.org/fhir/us/core/StructureDefinition/us-core-medicationrequest'],
        'Observation' => [
          'http://hl7.org/fhir/us/core/StructureDefinition/us-core-observation-lab',
          'http://hl7.org/fhir/us/core/StructureDefinition/pediatric-bmi-for-age',
          'http://hl7.org/fhir/us/core/StructureDefinition/pediatric-weight-for-height',
          'http://hl7.org/fhir/us/core/StructureDefinition/us-core-pulse-oximetry',
          'http://hl7.org/fhir/us/core/StructureDefinition/us-core-smokingstatus',
          'http://hl7.org/fhir/StructureDefinition/bp',
          'http://hl7.org/fhir/StructureDefinition/bodyheight',
          'http://hl7.org/fhir/StructureDefinition/bodyweight',
          'http://hl7.org/fhir/StructureDefinition/heartrate',
          'http://hl7.org/fhir/StructureDefinition/resprate',
          'http://hl7.org/fhir/StructureDefinition/bodytemp',
          'http://hl7.org/fhir/StructureDefinition/headcircum'
        ],
        'Organization' => ['http://hl7.org/fhir/us/core/StructureDefinition/us-core-organization'],
        'Patient' => ['http://hl7.org/fhir/us/core/StructureDefinition/us-core-patient'],
        'Practitioner' => ['http://hl7.org/fhir/us/core/StructureDefinition/us-core-practitioner'],
        'PractitionerRole' => ['http://hl7.org/fhir/us/core/StructureDefinition/us-core-practitionerrole'],
        'Procedure' => ['http://hl7.org/fhir/us/core/StructureDefinition/us-core-procedure'],
        'Provenance' => ['http://hl7.org/fhir/us/core/StructureDefinition/us-core-provenance']
      }.freeze

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

      test :conformance_support do
        metadata do
          id '02'
          name 'FHIR server supports the conformance interaction'
          link 'http://hl7.org/fhir/DSTU2/http.html#conformance'
          description %(
            The conformance 'whole system' interaction provides a method to get
            the conformance statement for the FHIR server. This test checks that
            the server responds to a `GET` request at the following endpoint:

            ```
            GET [base]/metadata
            ```

            This test checks the following SHALL requirement:

            > Applications SHALL return a resource that describes the
              functionality of the server end-point.

            [http://hl7.org/fhir/R4/http.html#capabilities](http://hl7.org/fhir/R4/http.html#capabilities)

            It does this by checking that the server responds with an HTTP OK
            200 status code and that the body of the response contains a valid
            [CapabilityStatement
            resource](http://hl7.org/fhir/R4/capabilitystatement.html). This
            test does not inspect the content of the Conformance resource to see
            if it contains the required information. It only checks to see if
            the RESTful interaction is supported and returns a valid
            CapabilityStatement resource.
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
            Checks that the FHIR version of the server matches the FHIR version
            expected by the tests. This test will inspect the
            CapabilityStatement returned by the server to verify the FHIR
            version of the server.
          )
        end

        pass 'Tests are not version dependent' if @instance.fhir_version.blank?

        # @client.detect_version is a symbol
        assert_equal(@instance.fhir_version.upcase, @client.detect_version.to_s.upcase, 'FHIR client version does not match with instance version.')
      end
      test :json_support do
        metadata do
          id '04'
          name 'FHIR server capability states JSON support'
          link 'http://hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html#behavior'
          description %(

            FHIR provides multiple [representation
            formats](https://www.hl7.org/fhir/formats.html) for resources,
            including JSON and XML. US Core profiles require servers to use the
            [JSON representation](https://www.hl7.org/fhir/json.html):

            [```The US Core Server **SHALL** Support json source formats for all
            US Core
            interactions.```](http://hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html#behavior)

            The FHIR capability interaction require servers to describe which
            formats are available for clients to use. The server must explicitly
            state that JSON is supported. This is located in the [format
            element](https://www.hl7.org/fhir/capabilitystatement-definitions.html#CapabilityStatement.format)
            of the CapabilityStatement Resource.

            This test checks that one of the following values are located in the
            format field.

            * json
            * application/json
            * application/fhir+json
          )
        end

        assert_valid_conformance

        assert json_formats.any? { |format| @conformance.format.include? format }, 'Conformance does not state support for json.'
      end

      test :profile_support do
        metadata do
          id '05'
          name 'Capability Statement lists support for required US Core Profiles'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html#behavior'
          description %(
           The US Core Implementation Guide states:

           ```
           The US Core Server SHALL:
           1. Support the US Core Patient resource profile.
           2. Support at least one additional resource profile from the list of
              US Core Profiles.
           ```
          )
        end

        assert_valid_conformance
        supported_resources = @server_capabilities.supported_resources
        supported_profiles = @server_capabilities.supported_profiles

        assert supported_resources.include?('Patient'), 'US Core Patient profile not supported'

        other_resources = PROFILES.keys.reject { |resource_type| resource_type == 'Patient' }
        other_resources_supported = other_resources.any? { |resource| supported_resources.include? resource }
        assert other_resources_supported, 'No US Core resources other than Patient are supported'

        PROFILES.each do |resource, profiles|
          next unless supported_resources.include? resource

          profiles.each do |profile|
            warning do
              message = "CapabilityStatement does not claim support for US Core #{resource} profile: #{profile}"
              assert supported_profiles&.include?(profile), message
            end
          end
        end
      end
    end
  end
end
