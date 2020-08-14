# frozen_string_literal: true

module Inferno
  module Sequence
    class ONCAccessVerifyRestrictedSequence < SequenceBase
      title 'Restricted Resource Type Access'

      description 'Verify that patients have control over which resource types can be accessed.'
      test_id_prefix 'AVR'
      details %(
        This test ensures that patients are able to grant or deny access to a subset of resources to an app.
        It also verifies that patients can prevent issuance of a refresh token by denying the `offline_access` scope.  The tester provides a list of resources
        that will be granted during the SMART App Launch process, and this test verifies that the scopes granted
        are consistent with what the tester provided.  It also formulates queries to ensure that the app
        is either given access to, or denied access to, the appropriate resource types based on those chosen
        by the tester.

        Resources that can be mapped to USCDI are checked in this test, including:

          * AllergyIntolerance
          * CarePlan
          * CareTeam
          * Condition
          * Device
          * DiagnosticReport
          * DocumentReference
          * Goal
          * Immunization
          * MedicationRequest
          * Observation
          * Procedure

        For each of the resources that can be mapped to USCDI data class or elements, this set of tests
        performs a minimum number of requests to determine if access to the resource type is appropriately allowed or denied given the
        scope granted.  In the case of the Patient resource, this test simply performs a read request.
        For other resources, it performs a search by patient that must be supported by the server.  In some cases,
        servers can return an error message if a status search parameter is not provided.  For these, the
        test will perform an additional search with the required status search parameter.

        This set of tests does not attempt to access resources that do not directly map to USCDI v1, including Encounter, Location,
        Organization, Practitioner, PractionerRole, and RelatedPerson.  It also does not test Provenance, as this
        resource type is accessed by queries through other resource types.  These resource types are accessed in the more
        comprehensive Single Patient Query tests.

        If the tester chooses to not grant access to a resource, the queries associated with that resource must
        result in either a 401 (Unauthorized) or 403 (Forbidden) status code.  The flexiblity provided here
        is due to some ambiguity in the specifications tested.
      )

      requires :onc_sl_url, :token, :patient_id, :received_scopes, :onc_sl_expected_resources

      def scopes
        @instance.received_scopes || @instance.onc_sl_scopes
      end

      def resource_access_as_scope
        @instance.onc_sl_expected_resources&.split(',')&.map { |resource| "patient/#{resource.strip}.read" }&.join(' ')
      end

      def assert_response_insufficient_scope(response)
        # This is intended for tests that are expecting the server to reject a
        # resource request due to user not authorizing the application for that
        # particular resource.  In early versions of this test, these tests
        # expected a 401 (Unauthorized), but after later review it seems
        # reasonable for a server to return 403 (Forbidden) instead.  This
        # assertion therefore allows either.

        message = "Bad response code: expected 403 (Forbidden) or 401 (Unauthorized), but found #{response.code}."
        assert [401, 403].include?(response.code), message
      end

      def url_property
        'onc_sl_url'
      end

      def scope_granting_access(resource, scopes)
        scopes.split(' ').find do |scope|
          ['patient/*.read', 'patient/*.*', "patient/#{resource}.read", "patient/#{resource}.*"].include? scope
        end
      end

      test :validate_right_scopes do
        metadata do
          id '01'
          name 'Scope granted is limited to those chosen by user during authorization.'

          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-patient'
          description %(

            This test confirms that the scopes granted during authorization match those that
            were expected for this launch based on input provided by the tester.

          )
        end

        skip_if @instance.received_scopes.nil?, 'A list of granted scopes was not provided to this test as required.'

        # Consider all directly-mapped USCDI resources only.  Do not fail based on the inclusion/Exclusion of Encounter, Practitioner
        # PractitionerRole, Location, Organization, or RelatedPerson because the SUT has flexibility to decide if those
        # should be included or not based on whether other resources are selected (e.g. if Observation then maybe it makes
        # sense to include Encounter scope) without having the user be in charge of that particular choice.

        all_resources = [
          'AllergyIntolerance',
          'CarePlan',
          'CareTeam',
          'Condition',
          'Device',
          'DiagnosticReport',
          'DocumentReference',
          'Goal',
          'Immunization',
          'MedicationRequest',
          'Observation',
          'Procedure',
          'Patient',
          'Provenance'
        ]
        allowed_resources = all_resources.select { |resource| scope_granting_access(resource, resource_access_as_scope).present? }
        denied_resources = all_resources - allowed_resources
        assert denied_resources.present?, "This test requires at least one resource to be denied, but the provided scope '#{@instance.received_scopes}' grants access to all resource types."
        received_scope_resources = all_resources.select { |resource| scope_granting_access(resource, @instance.received_scopes).present? }
        unexpected_resources = received_scope_resources - allowed_resources
        assert unexpected_resources.empty?, "This test expected the user to deny access to the following resources that are present in scopes received during token exchange response: #{unexpected_resources.join(', ')}"
        improperly_denied_resources = allowed_resources.reject { |resource| scope_granting_access(resource, @instance.received_scopes).present? }
        assert improperly_denied_resources.empty?, "This test expected the user to grant access to the following resources that are not received during token exhange response: #{improperly_denied_resources.join(', ')}"
        assert @instance.received_scopes.split(' ').exclude?('offline_access'), 'This test expects the user to deny offline access to demonstrate that refresh tokens require user approval'
        pass "Resources to be denied: #{denied_resources.join(',')}"
      end

      test :validate_patient_authorization do
        metadata do
          id '02'
          name 'Access to Patient resource granted and patient resource can be read.'
          link 'http://www.hl7.org/fhir/smart-app-launch/scopes-and-launch-context/index.html'
          description %(
            This test ensures that the authorization service has granted access to the Patient resource
            and that the patient resource can be read without an authorization error.
          )
        end
        skip_if @instance.patient_id.nil?, 'Patient ID not provided to test. The patient ID is typically provided during in a SMART launch context.'
        skip_if @instance.received_scopes.nil?, 'No scopes were received.'

        @client = FHIR::Client.for_testing_instance(@instance, url_property: url_property)
        @client.set_bearer_token(@instance.token) unless @client.nil? || @instance.nil? || @instance.token.nil?
        @client&.monitor_requests

        reply = @client.read(FHIR::Patient, @instance.patient_id)

        access_allowed_scope = scope_granting_access('Patient', resource_access_as_scope)

        if access_allowed_scope.present?
          assert_response_ok reply
          pass "Access expected to be granted and request properly returned #{reply&.response&.dig(:code)}"
        else

          assert_response_insufficient_scope reply

        end
      end

      test :validate_allergyintolerance_authorization do
        metadata do
          id '03'
          name 'Access to AllergyIntolerance resources are restricted properly based on patient-selected scope'
          link 'http://www.hl7.org/fhir/smart-app-launch/scopes-and-launch-context/index.html'
          description %(
            This test ensures that access to the AllergyIntolerance is granted or denied based on the
            selection by the tester prior to the execution of the test.  If the tester indicated that access
            will be granted to this resource, this test verifies that
            a search by patient in this resource does not result in an access denied result.  If the tester indicated that
            access will be denied for this resource, this verifies that
            search by patient in the resource results in an access denied result.
          )
        end

        skip_if @instance.patient_id.nil?, 'Patient ID not provided to test.'
        skip_if @instance.received_scopes.nil?, 'No scopes were received.'

        params = {
          patient: @instance.patient_id
        }

        options = {
          search: {
            flag: false,
            compartment: nil,
            parameters: params
          }
        }
        reply = @client.search('AllergyIntolerance', options)
        access_allowed_scope = scope_granting_access('AllergyIntolerance', resource_access_as_scope)

        if access_allowed_scope.present?

          if reply.code == 400
            error_message = 'Server is expected to grant access to the resource.  A search without a status can return an HTTP 400 status, but must also must include an OperationOutcome. No OperationOutcome is present in the body of the response.'
            begin
              parsed_reply = JSON.parse(reply.body)
              assert parsed_reply['resourceType'] == 'OperationOutcome', error_message
            rescue JSON::ParserError
              assert false, error_message
            end

            options[:search][:parameters].merge!('clinical-status': 'active')

            reply = @client.search('AllergyIntolerance', options)
          end

          assert_response_ok reply
          pass "Access expected to be granted and request properly returned #{reply&.response&.dig(:code)}"

        else
          assert_response_insufficient_scope reply
        end
      end

      test :validate_careplan_authorization do
        metadata do
          id '04'
          name 'Access to CarePlan resources are restricted properly based on patient-selected scope'
          link 'http://www.hl7.org/fhir/smart-app-launch/scopes-and-launch-context/index.html'
          description %(
            This test ensures that access to the CarePlan is granted or denied based on the
            selection by the tester prior to the execution of the test.  If the tester indicated that access
            will be granted to this resource, this test verifies that
            a search by patient in this resource does not result in an access denied result.  If the tester indicated that
            access will be denied for this resource, this verifies that
            search by patient in the resource results in an access denied result.
          )
        end

        skip_if @instance.patient_id.nil?, 'Patient ID not provided to test.'
        skip_if @instance.received_scopes.nil?, 'No scopes were received.'

        params = {
          patient: @instance.patient_id,
          category: 'assess-plan'
        }

        options = {
          search: {
            flag: false,
            compartment: nil,
            parameters: params
          }
        }
        reply = @client.search('CarePlan', options)
        access_allowed_scope = scope_granting_access('CarePlan', resource_access_as_scope)

        if access_allowed_scope.present?

          if reply.code == 400
            error_message = 'Server is expected to grant access to the resource.  A search without a status can return an HTTP 400 status, but must also must include an OperationOutcome. No OperationOutcome is present in the body of the response.'
            begin
              parsed_reply = JSON.parse(reply.body)
              assert parsed_reply['resourceType'] == 'OperationOutcome', error_message
            rescue JSON::ParserError
              assert false, error_message
            end

            options[:search][:parameters].merge!('status': 'active')

            reply = @client.search('CarePlan', options)
          end

          assert_response_ok reply
          pass "Access expected to be granted and request properly returned #{reply&.response&.dig(:code)}"

        else
          assert_response_insufficient_scope reply
        end
      end

      test :validate_careteam_authorization do
        metadata do
          id '05'
          name 'Access to CareTeam resources are restricted properly based on patient-selected scope'
          link 'http://www.hl7.org/fhir/smart-app-launch/scopes-and-launch-context/index.html'
          description %(
            This test ensures that access to the CareTeam is granted or denied based on the
            selection by the tester prior to the execution of the test.  If the tester indicated that access
            will be granted to this resource, this test verifies that
            a search by patient in this resource does not result in an access denied result.  If the tester indicated that
            access will be denied for this resource, this verifies that
            search by patient in the resource results in an access denied result.
          )
        end

        skip_if @instance.patient_id.nil?, 'Patient ID not provided to test.'
        skip_if @instance.received_scopes.nil?, 'No scopes were received.'

        params = {
          patient: @instance.patient_id,
          status: 'active'
        }

        options = {
          search: {
            flag: false,
            compartment: nil,
            parameters: params
          }
        }
        reply = @client.search('CareTeam', options)
        access_allowed_scope = scope_granting_access('CareTeam', resource_access_as_scope)

        if access_allowed_scope.present?

          if reply.code == 400
            error_message = 'Server is expected to grant access to the resource.  A search without a status can return an HTTP 400 status, but must also must include an OperationOutcome. No OperationOutcome is present in the body of the response.'
            begin
              parsed_reply = JSON.parse(reply.body)
              assert parsed_reply['resourceType'] == 'OperationOutcome', error_message
            rescue JSON::ParserError
              assert false, error_message
            end

            options[:search][:parameters].merge!('status': 'active')

            reply = @client.search('CareTeam', options)
          end

          assert_response_ok reply
          pass "Access expected to be granted and request properly returned #{reply&.response&.dig(:code)}"

        else
          assert_response_insufficient_scope reply
        end
      end

      test :validate_condition_authorization do
        metadata do
          id '06'
          name 'Access to Condition resources are restricted properly based on patient-selected scope'
          link 'http://www.hl7.org/fhir/smart-app-launch/scopes-and-launch-context/index.html'
          description %(
            This test ensures that access to the Condition is granted or denied based on the
            selection by the tester prior to the execution of the test.  If the tester indicated that access
            will be granted to this resource, this test verifies that
            a search by patient in this resource does not result in an access denied result.  If the tester indicated that
            access will be denied for this resource, this verifies that
            search by patient in the resource results in an access denied result.
          )
        end

        skip_if @instance.patient_id.nil?, 'Patient ID not provided to test.'
        skip_if @instance.received_scopes.nil?, 'No scopes were received.'

        params = {
          patient: @instance.patient_id
        }

        options = {
          search: {
            flag: false,
            compartment: nil,
            parameters: params
          }
        }
        reply = @client.search('Condition', options)
        access_allowed_scope = scope_granting_access('Condition', resource_access_as_scope)

        if access_allowed_scope.present?

          if reply.code == 400
            error_message = 'Server is expected to grant access to the resource.  A search without a status can return an HTTP 400 status, but must also must include an OperationOutcome. No OperationOutcome is present in the body of the response.'
            begin
              parsed_reply = JSON.parse(reply.body)
              assert parsed_reply['resourceType'] == 'OperationOutcome', error_message
            rescue JSON::ParserError
              assert false, error_message
            end

            options[:search][:parameters].merge!('clinical-status': 'active')

            reply = @client.search('Condition', options)
          end

          assert_response_ok reply
          pass "Access expected to be granted and request properly returned #{reply&.response&.dig(:code)}"

        else
          assert_response_insufficient_scope reply
        end
      end

      test :validate_device_authorization do
        metadata do
          id '07'
          name 'Access to Device resources are restricted properly based on patient-selected scope'
          link 'http://www.hl7.org/fhir/smart-app-launch/scopes-and-launch-context/index.html'
          description %(
            This test ensures that access to the Device is granted or denied based on the
            selection by the tester prior to the execution of the test.  If the tester indicated that access
            will be granted to this resource, this test verifies that
            a search by patient in this resource does not result in an access denied result.  If the tester indicated that
            access will be denied for this resource, this verifies that
            search by patient in the resource results in an access denied result.
          )
        end

        skip_if @instance.patient_id.nil?, 'Patient ID not provided to test.'
        skip_if @instance.received_scopes.nil?, 'No scopes were received.'

        params = {
          patient: @instance.patient_id
        }

        options = {
          search: {
            flag: false,
            compartment: nil,
            parameters: params
          }
        }
        reply = @client.search('Device', options)
        access_allowed_scope = scope_granting_access('Device', resource_access_as_scope)

        if access_allowed_scope.present?

          assert_response_ok reply
          pass "Access expected to be granted and request properly returned #{reply&.response&.dig(:code)}"

        else
          assert_response_insufficient_scope reply
        end
      end

      test :validate_diagnosticreport_authorization do
        metadata do
          id '08'
          name 'Access to DiagnosticReport resources are restricted properly based on patient-selected scope'
          link 'http://www.hl7.org/fhir/smart-app-launch/scopes-and-launch-context/index.html'
          description %(
            This test ensures that access to the DiagnosticReport is granted or denied based on the
            selection by the tester prior to the execution of the test.  If the tester indicated that access
            will be granted to this resource, this test verifies that
            a search by patient in this resource does not result in an access denied result.  If the tester indicated that
            access will be denied for this resource, this verifies that
            search by patient in the resource results in an access denied result.
          )
        end

        skip_if @instance.patient_id.nil?, 'Patient ID not provided to test.'
        skip_if @instance.received_scopes.nil?, 'No scopes were received.'

        params = {
          patient: @instance.patient_id,
          category: 'LAB'
        }

        options = {
          search: {
            flag: false,
            compartment: nil,
            parameters: params
          }
        }
        reply = @client.search('DiagnosticReport', options)
        access_allowed_scope = scope_granting_access('DiagnosticReport', resource_access_as_scope)

        if access_allowed_scope.present?

          if reply.code == 400
            error_message = 'Server is expected to grant access to the resource.  A search without a status can return an HTTP 400 status, but must also must include an OperationOutcome. No OperationOutcome is present in the body of the response.'
            begin
              parsed_reply = JSON.parse(reply.body)
              assert parsed_reply['resourceType'] == 'OperationOutcome', error_message
            rescue JSON::ParserError
              assert false, error_message
            end

            options[:search][:parameters].merge!('status': 'final')

            reply = @client.search('DiagnosticReport', options)
          end

          assert_response_ok reply
          pass "Access expected to be granted and request properly returned #{reply&.response&.dig(:code)}"

        else
          assert_response_insufficient_scope reply
        end
      end

      test :validate_documentreference_authorization do
        metadata do
          id '09'
          name 'Access to DocumentReference resources are restricted properly based on patient-selected scope'
          link 'http://www.hl7.org/fhir/smart-app-launch/scopes-and-launch-context/index.html'
          description %(
            This test ensures that access to the DocumentReference is granted or denied based on the
            selection by the tester prior to the execution of the test.  If the tester indicated that access
            will be granted to this resource, this test verifies that
            a search by patient in this resource does not result in an access denied result.  If the tester indicated that
            access will be denied for this resource, this verifies that
            search by patient in the resource results in an access denied result.
          )
        end

        skip_if @instance.patient_id.nil?, 'Patient ID not provided to test.'
        skip_if @instance.received_scopes.nil?, 'No scopes were received.'

        params = {
          patient: @instance.patient_id
        }

        options = {
          search: {
            flag: false,
            compartment: nil,
            parameters: params
          }
        }
        reply = @client.search('DocumentReference', options)
        access_allowed_scope = scope_granting_access('DocumentReference', resource_access_as_scope)

        if access_allowed_scope.present?

          if reply.code == 400
            error_message = 'Server is expected to grant access to the resource.  A search without a status can return an HTTP 400 status, but must also must include an OperationOutcome. No OperationOutcome is present in the body of the response.'
            begin
              parsed_reply = JSON.parse(reply.body)
              assert parsed_reply['resourceType'] == 'OperationOutcome', error_message
            rescue JSON::ParserError
              assert false, error_message
            end

            options[:search][:parameters].merge!('status': 'current')

            reply = @client.search('DocumentReference', options)
          end

          assert_response_ok reply
          pass "Access expected to be granted and request properly returned #{reply&.response&.dig(:code)}"

        else
          assert_response_insufficient_scope reply
        end
      end

      test :validate_goal_authorization do
        metadata do
          id '10'
          name 'Access to Goal resources are restricted properly based on patient-selected scope'
          link 'http://www.hl7.org/fhir/smart-app-launch/scopes-and-launch-context/index.html'
          description %(
            This test ensures that access to the Goal is granted or denied based on the
            selection by the tester prior to the execution of the test.  If the tester indicated that access
            will be granted to this resource, this test verifies that
            a search by patient in this resource does not result in an access denied result.  If the tester indicated that
            access will be denied for this resource, this verifies that
            search by patient in the resource results in an access denied result.
          )
        end

        skip_if @instance.patient_id.nil?, 'Patient ID not provided to test.'
        skip_if @instance.received_scopes.nil?, 'No scopes were received.'

        params = {
          patient: @instance.patient_id
        }

        options = {
          search: {
            flag: false,
            compartment: nil,
            parameters: params
          }
        }
        reply = @client.search('Goal', options)
        access_allowed_scope = scope_granting_access('Goal', resource_access_as_scope)

        if access_allowed_scope.present?

          if reply.code == 400
            error_message = 'Server is expected to grant access to the resource.  A search without a status can return an HTTP 400 status, but must also must include an OperationOutcome. No OperationOutcome is present in the body of the response.'
            begin
              parsed_reply = JSON.parse(reply.body)
              assert parsed_reply['resourceType'] == 'OperationOutcome', error_message
            rescue JSON::ParserError
              assert false, error_message
            end

            options[:search][:parameters].merge!('status': 'active')

            reply = @client.search('Goal', options)
          end

          assert_response_ok reply
          pass "Access expected to be granted and request properly returned #{reply&.response&.dig(:code)}"

        else
          assert_response_insufficient_scope reply
        end
      end

      test :validate_immunization_authorization do
        metadata do
          id '11'
          name 'Access to Immunization resources are restricted properly based on patient-selected scope'
          link 'http://www.hl7.org/fhir/smart-app-launch/scopes-and-launch-context/index.html'
          description %(
            This test ensures that access to the Immunization is granted or denied based on the
            selection by the tester prior to the execution of the test.  If the tester indicated that access
            will be granted to this resource, this test verifies that
            a search by patient in this resource does not result in an access denied result.  If the tester indicated that
            access will be denied for this resource, this verifies that
            search by patient in the resource results in an access denied result.
          )
        end

        skip_if @instance.patient_id.nil?, 'Patient ID not provided to test.'
        skip_if @instance.received_scopes.nil?, 'No scopes were received.'

        params = {
          patient: @instance.patient_id
        }

        options = {
          search: {
            flag: false,
            compartment: nil,
            parameters: params
          }
        }
        reply = @client.search('Immunization', options)
        access_allowed_scope = scope_granting_access('Immunization', resource_access_as_scope)

        if access_allowed_scope.present?

          if reply.code == 400
            error_message = 'Server is expected to grant access to the resource.  A search without a status can return an HTTP 400 status, but must also must include an OperationOutcome. No OperationOutcome is present in the body of the response.'
            begin
              parsed_reply = JSON.parse(reply.body)
              assert parsed_reply['resourceType'] == 'OperationOutcome', error_message
            rescue JSON::ParserError
              assert false, error_message
            end

            options[:search][:parameters].merge!('status': 'completed')

            reply = @client.search('Immunization', options)
          end

          assert_response_ok reply
          pass "Access expected to be granted and request properly returned #{reply&.response&.dig(:code)}"

        else
          assert_response_insufficient_scope reply
        end
      end

      test :validate_medicationrequest_authorization do
        metadata do
          id '12'
          name 'Access to MedicationRequest resources are restricted properly based on patient-selected scope'
          link 'http://www.hl7.org/fhir/smart-app-launch/scopes-and-launch-context/index.html'
          description %(
            This test ensures that access to the MedicationRequest is granted or denied based on the
            selection by the tester prior to the execution of the test.  If the tester indicated that access
            will be granted to this resource, this test verifies that
            a search by patient in this resource does not result in an access denied result.  If the tester indicated that
            access will be denied for this resource, this verifies that
            search by patient in the resource results in an access denied result.
          )
        end

        skip_if @instance.patient_id.nil?, 'Patient ID not provided to test.'
        skip_if @instance.received_scopes.nil?, 'No scopes were received.'

        params = {
          patient: @instance.patient_id,
          intent: 'order'
        }

        options = {
          search: {
            flag: false,
            compartment: nil,
            parameters: params
          }
        }
        reply = @client.search('MedicationRequest', options)
        access_allowed_scope = scope_granting_access('MedicationRequest', resource_access_as_scope)

        if access_allowed_scope.present?

          if reply.code == 400
            error_message = 'Server is expected to grant access to the resource.  A search without a status can return an HTTP 400 status, but must also must include an OperationOutcome. No OperationOutcome is present in the body of the response.'
            begin
              parsed_reply = JSON.parse(reply.body)
              assert parsed_reply['resourceType'] == 'OperationOutcome', error_message
            rescue JSON::ParserError
              assert false, error_message
            end

            options[:search][:parameters].merge!('status': 'active')

            reply = @client.search('MedicationRequest', options)
          end

          assert_response_ok reply
          pass "Access expected to be granted and request properly returned #{reply&.response&.dig(:code)}"

        else
          assert_response_insufficient_scope reply
        end
      end

      test :validate_observation_authorization do
        metadata do
          id '13'
          name 'Access to Observation resources are restricted properly based on patient-selected scope'
          link 'http://www.hl7.org/fhir/smart-app-launch/scopes-and-launch-context/index.html'
          description %(
            This test ensures that access to the Observation is granted or denied based on the
            selection by the tester prior to the execution of the test.  If the tester indicated that access
            will be granted to this resource, this test verifies that
            a search by patient in this resource does not result in an access denied result.  If the tester indicated that
            access will be denied for this resource, this verifies that
            search by patient in the resource results in an access denied result.
          )
        end

        skip_if @instance.patient_id.nil?, 'Patient ID not provided to test.'
        skip_if @instance.received_scopes.nil?, 'No scopes were received.'

        params = {
          patient: @instance.patient_id,
          code: '2708-6'
        }

        options = {
          search: {
            flag: false,
            compartment: nil,
            parameters: params
          }
        }
        reply = @client.search('Observation', options)
        access_allowed_scope = scope_granting_access('Observation', resource_access_as_scope)

        if access_allowed_scope.present?

          if reply.code == 400
            error_message = 'Server is expected to grant access to the resource.  A search without a status can return an HTTP 400 status, but must also must include an OperationOutcome. No OperationOutcome is present in the body of the response.'
            begin
              parsed_reply = JSON.parse(reply.body)
              assert parsed_reply['resourceType'] == 'OperationOutcome', error_message
            rescue JSON::ParserError
              assert false, error_message
            end

            options[:search][:parameters].merge!('status': 'final')

            reply = @client.search('Observation', options)
          end

          assert_response_ok reply
          pass "Access expected to be granted and request properly returned #{reply&.response&.dig(:code)}"

        else
          assert_response_insufficient_scope reply
        end
      end

      test :validate_procedure_authorization do
        metadata do
          id '14'
          name 'Access to Procedure resources are restricted properly based on patient-selected scope'
          link 'http://www.hl7.org/fhir/smart-app-launch/scopes-and-launch-context/index.html'
          description %(
            This test ensures that access to the Procedure is granted or denied based on the
            selection by the tester prior to the execution of the test.  If the tester indicated that access
            will be granted to this resource, this test verifies that
            a search by patient in this resource does not result in an access denied result.  If the tester indicated that
            access will be denied for this resource, this verifies that
            search by patient in the resource results in an access denied result.
          )
        end

        skip_if @instance.patient_id.nil?, 'Patient ID not provided to test.'
        skip_if @instance.received_scopes.nil?, 'No scopes were received.'

        params = {
          patient: @instance.patient_id
        }

        options = {
          search: {
            flag: false,
            compartment: nil,
            parameters: params
          }
        }
        reply = @client.search('Procedure', options)
        access_allowed_scope = scope_granting_access('Procedure', resource_access_as_scope)

        if access_allowed_scope.present?

          if reply.code == 400
            error_message = 'Server is expected to grant access to the resource.  A search without a status can return an HTTP 400 status, but must also must include an OperationOutcome. No OperationOutcome is present in the body of the response.'
            begin
              parsed_reply = JSON.parse(reply.body)
              assert parsed_reply['resourceType'] == 'OperationOutcome', error_message
            rescue JSON::ParserError
              assert false, error_message
            end

            options[:search][:parameters].merge!('status': 'completed')

            reply = @client.search('Procedure', options)
          end

          assert_response_ok reply
          pass "Access expected to be granted and request properly returned #{reply&.response&.dig(:code)}"

        else
          assert_response_insufficient_scope reply
        end
      end
    end
  end
end
