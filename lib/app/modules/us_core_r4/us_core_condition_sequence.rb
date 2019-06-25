# frozen_string_literal: true

module Inferno
  module Sequence
    class UsCoreR4ConditionSequence < SequenceBase
      group 'US Core R4 Profile Conformance'

      title 'Condition Tests'

      description 'Verify that Condition resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

      test_id_prefix 'Condition' # change me

      requires :token, :patient_id
      conformance_supports :Condition

      def validate_resource_item(resource, property, value)
        case property

        when 'category'
          codings = resource&.category&.first&.coding
          assert !codings.nil?, 'category on resource did not match category requested'
          assert codings.any? { |coding| !coding.try(:code).nil? && coding.try(:code) == value }, 'category on resource did not match category requested'

        when 'clinical-status'
          codings = resource&.clinicalStatus&.coding
          assert !codings.nil?, 'clinical-status on resource did not match clinical-status requested'
          assert codings.any? { |coding| !coding.try(:code).nil? && coding.try(:code) == value }, 'clinical-status on resource did not match clinical-status requested'

        when 'patient'
          assert resource&.subject&.reference&.include?(value), 'patient on resource does not match patient requested'

        when 'onset-date'

        when 'code'
          codings = resource&.code&.coding
          assert !codings.nil?, 'code on resource did not match code requested'
          assert codings.any? { |coding| !coding.try(:code).nil? && coding.try(:code) == value }, 'code on resource did not match code requested'

        end
      end

      details %(

        The #{title} Sequence tests `#{title.gsub(/\s+/, '')}` resources associated with the provided patient.  The resources
        returned will be checked for consistency against the [Condition Argonaut Profile](https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-condition)

      )

      @resources_found = false

      test 'Server rejects Condition search without authorization' do
        metadata do
          id '01'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
          )
          versions :r4
        end

        @client.set_no_auth
        skip 'Could not verify this functionality when bearer token is not set' if @instance.token.blank?

        reply = get_resource_by_params(versioned_resource_class('Condition'), patient: @instance.patient_id)
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply
      end

      test 'Server returns expected results from Condition search by patient' do
        metadata do
          id '02'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        patient_val = @instance.patient_id
        search_params = { 'patient': patient_val }

        reply = get_resource_by_params(versioned_resource_class('Condition'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)

        resource_count = reply&.resource&.entry&.length || 0
        @resources_found = true if resource_count.positive?

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        @condition = reply.try(:resource).try(:entry).try(:first).try(:resource)
        @condition_ary = reply&.resource&.entry&.map { |entry| entry&.resource }
        validate_search_reply(versioned_resource_class('Condition'), reply, search_params)
        save_resource_ids_in_bundle(versioned_resource_class('Condition'), reply)
      end

      test 'Server returns expected results from Condition search by patient+onset-date' do
        metadata do
          id '03'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@condition.nil?, 'Expected valid Condition resource to be present'

        patient_val = @instance.patient_id
        onset_date_val = @condition&.onsetDateTime
        search_params = { 'patient': patient_val, 'onset-date': onset_date_val }

        reply = get_resource_by_params(versioned_resource_class('Condition'), search_params)
        assert_response_ok(reply)
      end

      test 'Server returns expected results from Condition search by patient+category' do
        metadata do
          id '04'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@condition.nil?, 'Expected valid Condition resource to be present'

        patient_val = @instance.patient_id
        category_val = @condition&.category&.first&.coding&.first&.code
        search_params = { 'patient': patient_val, 'category': category_val }

        reply = get_resource_by_params(versioned_resource_class('Condition'), search_params)
        assert_response_ok(reply)
      end

      test 'Server returns expected results from Condition search by patient+code' do
        metadata do
          id '05'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@condition.nil?, 'Expected valid Condition resource to be present'

        patient_val = @instance.patient_id
        code_val = @condition&.code&.coding&.first&.code
        search_params = { 'patient': patient_val, 'code': code_val }

        reply = get_resource_by_params(versioned_resource_class('Condition'), search_params)
        assert_response_ok(reply)
      end

      test 'Server returns expected results from Condition search by patient+clinical-status' do
        metadata do
          id '06'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@condition.nil?, 'Expected valid Condition resource to be present'

        patient_val = @instance.patient_id
        clinical_status_val = @condition&.clinicalStatus&.coding&.first&.code
        search_params = { 'patient': patient_val, 'clinical-status': clinical_status_val }

        reply = get_resource_by_params(versioned_resource_class('Condition'), search_params)
        assert_response_ok(reply)
      end

      test 'Condition read resource supported' do
        metadata do
          id '07'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:Condition, [:read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_read_reply(@condition, versioned_resource_class('Condition'))
      end

      test 'Condition vread resource supported' do
        metadata do
          id '08'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:Condition, [:vread])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_vread_reply(@condition, versioned_resource_class('Condition'))
      end

      test 'Condition history resource supported' do
        metadata do
          id '09'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:Condition, [:history])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_history_reply(@condition, versioned_resource_class('Condition'))
      end

      test 'Demonstrates that the server can supply must supported elements' do
        metadata do
          id '10'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/general-guidance.html/#must-support'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information' unless @condition_ary&.any?
        must_support_elements = [
          'Condition.clinicalStatus',
          'Condition.verificationStatus',
          'Condition.category',
          'Condition.code',
          'Condition.subject'
        ]
        must_support_elements.each do |path|
          element_found = false
          @condition_ary&.each do |resource|
            truncated_path = path.gsub('Condition.', '')
            already_found = @instance.must_support_confirmed.include?(path)
            element_found = already_found || can_resolve_path(resource, truncated_path)
            @instance.must_support_confirmed += "#{path}," if element_found && !already_found
            break if element_found
          end
          skip "Could not find #{path} in the provided resource" unless element_found
        end
        @instance.save!
      end

      test 'Condition resources associated with Patient conform to US Core R4 profiles' do
        metadata do
          id '11'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-condition.json'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        test_resources_against_profile('Condition')
      end

      test 'All references can be resolved' do
        metadata do
          id '12'
          link 'https://www.hl7.org/fhir/DSTU2/references.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:Condition, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_reference_resolutions(@condition)
      end
    end
  end
end
