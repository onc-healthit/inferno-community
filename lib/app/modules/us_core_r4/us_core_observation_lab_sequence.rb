# frozen_string_literal: true

module Inferno
  module Sequence
    class UsCoreR4ObservationLabSequence < SequenceBase
      group 'US Core R4 Profile Conformance'

      title 'ObservationLab Tests'

      description 'Verify that Observation resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

      test_id_prefix 'Observation' # change me

      requires :token, :patient_id
      conformance_supports :Observation

      def validate_resource_item(resource, property, value)
        case property

        when 'status'
          assert resource&.status == value, 'status on resource did not match status requested'

        when 'category'
          codings = resource&.category&.first&.coding
          assert !codings.nil?, 'category on resource did not match category requested'
          assert codings.any? { |coding| !coding.try(:code).nil? && coding.try(:code) == value }, 'category on resource did not match category requested'

        when 'code'
          codings = resource&.code&.coding
          assert !codings.nil?, 'code on resource did not match code requested'
          assert codings.any? { |coding| !coding.try(:code).nil? && coding.try(:code) == value }, 'code on resource did not match code requested'

        when 'date'

        when 'patient'
          assert resource&.subject&.reference&.include?(value), 'patient on resource does not match patient requested'

        end
      end

      details %(

        The #{title} Sequence tests `#{title.gsub(/\s+/, '')}` resources associated with the provided patient.  The resources
        returned will be checked for consistency against the [ObservationLab Argonaut Profile](https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-observation-lab)

      )

      @resources_found = false

      test 'Server rejects Observation search without authorization' do
        metadata do
          id '01'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
          )
          versions :r4
        end

        @client.set_no_auth
        skip 'Could not verify this functionality when bearer token is not set' if @instance.token.blank?

        reply = get_resource_by_params(versioned_resource_class('Observation'), patient: @instance.patient_id)
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply
      end

      test 'Server returns expected results from Observation search by patient+category' do
        metadata do
          id '02'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        search_params = { patient: @instance.patient_id, category: 'laboratory' }

        reply = get_resource_by_params(versioned_resource_class('Observation'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)

        resource_count = reply&.resource&.entry&.length || 0
        @resources_found = true if resource_count.positive?

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        @observation = reply.try(:resource).try(:entry).try(:first).try(:resource)
        @observation_ary = reply&.resource&.entry&.map { |entry| entry&.resource }
        validate_search_reply(versioned_resource_class('Observation'), reply, search_params)
        save_resource_ids_in_bundle(versioned_resource_class('Observation'), reply)
      end

      test 'Server returns expected results from Observation search by patient+code' do
        metadata do
          id '03'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@observation.nil?, 'Expected valid Observation resource to be present'

        patient_val = @instance.patient_id
        code_val = @observation&.code&.coding&.first&.code
        search_params = { 'patient': patient_val, 'code': code_val }

        reply = get_resource_by_params(versioned_resource_class('Observation'), search_params)
        assert_response_ok(reply)
      end

      test 'Server returns expected results from Observation search by patient+category+date' do
        metadata do
          id '04'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@observation.nil?, 'Expected valid Observation resource to be present'

        patient_val = @instance.patient_id
        category_val = @observation&.category&.first&.coding&.first&.code
        date_val = @observation&.effectiveDateTime
        search_params = { 'patient': patient_val, 'category': category_val, 'date': date_val }

        reply = get_resource_by_params(versioned_resource_class('Observation'), search_params)
        assert_response_ok(reply)
      end

      test 'Server returns expected results from Observation search by patient+code+date' do
        metadata do
          id '05'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@observation.nil?, 'Expected valid Observation resource to be present'

        patient_val = @instance.patient_id
        code_val = @observation&.code&.coding&.first&.code
        date_val = @observation&.effectiveDateTime
        search_params = { 'patient': patient_val, 'code': code_val, 'date': date_val }

        reply = get_resource_by_params(versioned_resource_class('Observation'), search_params)
        assert_response_ok(reply)
      end

      test 'Server returns expected results from Observation search by patient+category+status' do
        metadata do
          id '06'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@observation.nil?, 'Expected valid Observation resource to be present'

        patient_val = @instance.patient_id
        category_val = @observation&.category&.first&.coding&.first&.code
        status_val = @observation&.status
        search_params = { 'patient': patient_val, 'category': category_val, 'status': status_val }

        reply = get_resource_by_params(versioned_resource_class('Observation'), search_params)
        assert_response_ok(reply)
      end

      test 'Observation read resource supported' do
        metadata do
          id '07'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:Observation, [:read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_read_reply(@observation, versioned_resource_class('Observation'))
      end

      test 'Observation vread resource supported' do
        metadata do
          id '08'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:Observation, [:vread])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_vread_reply(@observation, versioned_resource_class('Observation'))
      end

      test 'Observation history resource supported' do
        metadata do
          id '09'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:Observation, [:history])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_history_reply(@observation, versioned_resource_class('Observation'))
      end

      test 'Observation resources associated with Patient conform to US Core R4 profiles' do
        metadata do
          id '10'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-observation-lab.json'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        test_resources_against_profile('Observation')
      end

      test 'At least one of every must support element is provided in any Observation for this patient.' do
        metadata do
          id '11'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/general-guidance.html/#must-support'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information' unless @observation_ary&.any?
        must_support_confirmed = {}
        must_support_elements = [
          'Observation.status',
          'Observation.category',
          'Observation.code',
          'Observation.subject',
          'Observation.effectivedateTime',
          'Observation.effectivePeriod',
          'Observation.valueQuantity',
          'Observation.valueCodeableConcept',
          'Observation.valuestring',
          'Observation.valueboolean',
          'Observation.valueinteger',
          'Observation.valueRange',
          'Observation.valueRatio',
          'Observation.valueSampledData',
          'Observation.valuetime',
          'Observation.valuedateTime',
          'Observation.valuePeriod',
          'Observation.dataAbsentReason'
        ]
        must_support_elements.each do |path|
          @observation_ary&.each do |resource|
            truncated_path = path.gsub('Observation.', '')
            must_support_confirmed[path] = true if can_resolve_path(resource, truncated_path)
            break if must_support_confirmed[path]
          end
          resource_count = @observation_ary.length

          skip "Could not find #{path} in any of the #{resource_count} provided Observation resource(s)" unless must_support_confirmed[path]
        end
        @instance.save!
      end

      test 'All references can be resolved' do
        metadata do
          id '12'
          link 'https://www.hl7.org/fhir/DSTU2/references.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:Observation, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_reference_resolutions(@observation)
      end
    end
  end
end
