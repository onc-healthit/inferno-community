# frozen_string_literal: true

module Inferno
  module Sequence
    class USCoreR4ConditionSequence < SequenceBase
      group 'US Core R4 Profile Conformance'

      title 'Condition Tests'

      description 'Verify that Condition resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

      test_id_prefix 'Condition' # change me

      requires :token, :patient_id
      conformance_supports :Condition

      def validate_resource_item(resource, property, value)
        case property

        when 'category'
          value_found = can_resolve_path(resource, 'category.coding.code') { |value_in_resource| value_in_resource == value }
          assert value_found, 'category on resource does not match category requested'

        when 'clinical-status'
          value_found = can_resolve_path(resource, 'clinicalStatus.coding.code') { |value_in_resource| value_in_resource == value }
          assert value_found, 'clinical-status on resource does not match clinical-status requested'

        when 'patient'
          value_found = can_resolve_path(resource, 'subject.reference') { |reference| [value, 'Patient/' + value].include? reference }
          assert value_found, 'patient on resource does not match patient requested'

        when 'onset-date'
          value_found = can_resolve_path(resource, 'onsetDateTime') do |date|
            validate_date_search(value, date)
          end
          assert value_found, 'onset-date on resource does not match onset-date requested'

        when 'code'
          value_found = can_resolve_path(resource, 'code.coding.code') { |value_in_resource| value_in_resource == value }
          assert value_found, 'code on resource does not match code requested'

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

        patient_val = @instance.patient_id
        search_params = { 'patient': patient_val }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Condition'), search_params)
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
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Condition'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)

        resource_count = reply&.resource&.entry&.length || 0
        @resources_found = true if resource_count.positive?

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        @search_results = {}
        @condition = reply.try(:resource).try(:entry).try(:first).try(:resource)
        @search_results['patient'] = reply&.resource&.entry&.map { |entry| entry&.resource }
        save_resource_ids_in_bundle(versioned_resource_class('Condition'), reply)
        validate_search_reply(versioned_resource_class('Condition'), reply, search_params)
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
        onset_date_val = resolve_element_from_path(@condition, 'onsetDateTime')
        search_params = { 'patient': patient_val, 'onset-date': onset_date_val }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Condition'), search_params)
        validate_search_reply(versioned_resource_class('Condition'), reply, search_params)
        assert_response_ok(reply)
        @search_results['patient,onset-date'] = reply&.resource&.entry&.map { |entry| entry&.resource }

        ['gt', 'lt', 'le'].each do |comparator|
          comparator_val = date_comparator_value(comparator, onset_date_val)
          comparator_search_params = { 'patient': patient_val, 'onset-date': comparator_val }
          reply = get_resource_by_params(versioned_resource_class('Condition'), comparator_search_params)
          validate_search_reply(versioned_resource_class('Condition'), reply, comparator_search_params)
          assert_response_ok(reply)
        end
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
        category_val = resolve_element_from_path(@condition, 'category.coding.code')
        search_params = { 'patient': patient_val, 'category': category_val }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Condition'), search_params)
        validate_search_reply(versioned_resource_class('Condition'), reply, search_params)
        assert_response_ok(reply)
        @search_results['patient,category'] = reply&.resource&.entry&.map { |entry| entry&.resource }
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
        code_val = resolve_element_from_path(@condition, 'code.coding.code')
        search_params = { 'patient': patient_val, 'code': code_val }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Condition'), search_params)
        validate_search_reply(versioned_resource_class('Condition'), reply, search_params)
        assert_response_ok(reply)
        @search_results['patient,code'] = reply&.resource&.entry&.map { |entry| entry&.resource }
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
        clinical_status_val = resolve_element_from_path(@condition, 'clinicalStatus.coding.code')
        search_params = { 'patient': patient_val, 'clinical-status': clinical_status_val }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Condition'), search_params)
        validate_search_reply(versioned_resource_class('Condition'), reply, search_params)
        assert_response_ok(reply)
        @search_results['patient,clinical-status'] = reply&.resource&.entry&.map { |entry| entry&.resource }
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

      test 'Condition resources associated with Patient conform to US Core R4 profiles' do
        metadata do
          id '10'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-condition.json'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        test_resources_against_profile('Condition')
      end

      test 'At least one of every must support element is provided in any Condition for this patient.' do
        metadata do
          id '11'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/general-guidance.html/#must-support'
          desc %(
          )
          versions :r4
        end

        must_support_confirmed = {}
        must_support_elements = [
          'Condition.clinicalStatus',
          'Condition.verificationStatus',
          'Condition.category',
          'Condition.code',
          'Condition.subject'
        ]
        must_support_elements.each do |path|
          @search_results.each do |_params, resources|
            resources&.each do |resource|
              truncated_path = path.gsub('Condition.', '')
              must_support_confirmed[path] = true if can_resolve_path(resource, truncated_path)
              break if must_support_confirmed[path]
            end
          end

          skip "Could not find #{path} in any of the provided Condition resource(s)" unless must_support_confirmed[path]
        end
      end

      test 'No results are being filtered.' do
        metadata do
          id '12'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        validate_filters(@search_results)
      end

      test 'All references can be resolved' do
        metadata do
          id '13'
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
