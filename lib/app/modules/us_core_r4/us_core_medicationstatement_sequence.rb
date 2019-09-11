# frozen_string_literal: true

module Inferno
  module Sequence
    class USCoreR4MedicationstatementSequence < SequenceBase
      group 'US Core R4 Profile Conformance'

      title 'MedicationStatement Tests'

      description 'Verify that MedicationStatement resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

      test_id_prefix 'MedicationStatement' # change me

      requires :token, :patient_id
      conformance_supports :MedicationStatement

      def validate_resource_item(resource, property, value)
        case property

        when 'status'
          value_found = can_resolve_path(resource, 'status') { |value_in_resource| value_in_resource == value }
          assert value_found, 'status on resource does not match status requested'

        when 'patient'
          value_found = can_resolve_path(resource, 'subject.reference') { |reference| [value, 'Patient/' + value].include? reference }
          assert value_found, 'patient on resource does not match patient requested'

        when 'effective'
          value_found = can_resolve_path(resource, 'effectiveDateTime') do |date|
            validate_date_search(value, date)
          end
          assert value_found, 'effective on resource does not match effective requested'

        end
      end

      details %(

        The #{title} Sequence tests `#{title.gsub(/\s+/, '')}` resources associated with the provided patient.  The resources
        returned will be checked for consistency against the [Medicationstatement Argonaut Profile](https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-medicationstatement)

      )

      @resources_found = false

      test 'Server rejects MedicationStatement search without authorization' do
        metadata do
          id '01'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
          )
          versions :r4
        end

        @client.set_no_auth
        skip 'Could not verify this functionality when bearer token is not set' if @instance.token.blank?

        patient_val = @instance.patient_id
        search_params = { 'patient': patient_val }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('MedicationStatement'), search_params)
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply
      end

      test 'Server returns expected results from MedicationStatement search by patient' do
        metadata do
          id '02'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        patient_val = @instance.patient_id
        search_params = { 'patient': patient_val }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('MedicationStatement'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)

        resource_count = reply&.resource&.entry&.length || 0
        @resources_found = true if resource_count.positive?

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        @medicationstatement = reply.try(:resource).try(:entry).try(:first).try(:resource)
        @medicationstatement_ary = reply&.resource&.entry&.map { |entry| entry&.resource }
        save_resource_ids_in_bundle(versioned_resource_class('MedicationStatement'), reply)
        save_delayed_sequence_references(@medicationstatement)
        validate_search_reply(versioned_resource_class('MedicationStatement'), reply, search_params)
      end

      test 'Server returns expected results from MedicationStatement search by patient+effective' do
        metadata do
          id '03'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          optional
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@medicationstatement.nil?, 'Expected valid MedicationStatement resource to be present'

        patient_val = @instance.patient_id
        effective_val = resolve_element_from_path(@medicationstatement, 'effectiveDateTime')
        search_params = { 'patient': patient_val, 'effective': effective_val }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('MedicationStatement'), search_params)
        validate_search_reply(versioned_resource_class('MedicationStatement'), reply, search_params)
        assert_response_ok(reply)

        ['gt', 'lt', 'le'].each do |comparator|
          comparator_val = date_comparator_value(comparator, effective_val)
          comparator_search_params = { 'patient': patient_val, 'effective': comparator_val }
          reply = get_resource_by_params(versioned_resource_class('MedicationStatement'), comparator_search_params)
          validate_search_reply(versioned_resource_class('MedicationStatement'), reply, comparator_search_params)
          assert_response_ok(reply)
        end
      end

      test 'Server returns expected results from MedicationStatement search by patient+status' do
        metadata do
          id '04'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          optional
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@medicationstatement.nil?, 'Expected valid MedicationStatement resource to be present'

        patient_val = @instance.patient_id
        status_val = resolve_element_from_path(@medicationstatement, 'status')
        search_params = { 'patient': patient_val, 'status': status_val }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('MedicationStatement'), search_params)
        validate_search_reply(versioned_resource_class('MedicationStatement'), reply, search_params)
        assert_response_ok(reply)
      end

      test 'MedicationStatement read resource supported' do
        metadata do
          id '05'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:MedicationStatement, [:read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_read_reply(@medicationstatement, versioned_resource_class('MedicationStatement'))
      end

      test 'MedicationStatement vread resource supported' do
        metadata do
          id '06'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:MedicationStatement, [:vread])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_vread_reply(@medicationstatement, versioned_resource_class('MedicationStatement'))
      end

      test 'MedicationStatement history resource supported' do
        metadata do
          id '07'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:MedicationStatement, [:history])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_history_reply(@medicationstatement, versioned_resource_class('MedicationStatement'))
      end

      test 'MedicationStatement resources associated with Patient conform to US Core R4 profiles' do
        metadata do
          id '08'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-medicationstatement.json'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        test_resources_against_profile('MedicationStatement')
      end

      test 'At least one of every must support element is provided in any MedicationStatement for this patient.' do
        metadata do
          id '09'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/general-guidance.html/#must-support'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information' unless @medicationstatement_ary&.any?
        must_support_confirmed = {}
        must_support_elements = [
          'MedicationStatement.status',
          'MedicationStatement.medicationCodeableConcept',
          'MedicationStatement.medicationReference',
          'MedicationStatement.subject',
          'MedicationStatement.effectiveDateTime',
          'MedicationStatement.effectivePeriod',
          'MedicationStatement.dateAsserted',
          'MedicationStatement.derivedFrom'
        ]
        must_support_elements.each do |path|
          @medicationstatement_ary&.each do |resource|
            truncated_path = path.gsub('MedicationStatement.', '')
            must_support_confirmed[path] = true if can_resolve_path(resource, truncated_path)
            break if must_support_confirmed[path]
          end
          resource_count = @medicationstatement_ary.length

          skip "Could not find #{path} in any of the #{resource_count} provided MedicationStatement resource(s)" unless must_support_confirmed[path]
        end
        @instance.save!
      end

      test 'All references can be resolved' do
        metadata do
          id '10'
          link 'https://www.hl7.org/fhir/DSTU2/references.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:MedicationStatement, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_reference_resolutions(@medicationstatement)
      end
    end
  end
end
