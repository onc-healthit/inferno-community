# frozen_string_literal: true

module Inferno
  module Sequence
    class USCore300CareplanSequence < SequenceBase
      title 'CarePlan Tests'

      description 'Verify that CarePlan resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

      test_id_prefix 'USCCP'

      requires :token, :patient_id
      conformance_supports :CarePlan

      def validate_resource_item(resource, property, value)
        case property

        when 'category'
          value_found = can_resolve_path(resource, 'category.coding.code') { |value_in_resource| value_in_resource == value }
          assert value_found, 'category on resource does not match category requested'

        when 'date'
          value_found = can_resolve_path(resource, 'period') do |period|
            validate_period_search(value, period)
          end
          assert value_found, 'date on resource does not match date requested'

        when 'patient'
          value_found = can_resolve_path(resource, 'subject.reference') { |reference| [value, 'Patient/' + value].include? reference }
          assert value_found, 'patient on resource does not match patient requested'

        when 'status'
          value_found = can_resolve_path(resource, 'status') { |value_in_resource| value_in_resource == value }
          assert value_found, 'status on resource does not match status requested'

        end
      end

      details %(

        The #{title} Sequence tests `#{title.gsub(/\s+/, '')}` resources associated with the provided patient.

      )

      @resources_found = false

      test 'Server rejects CarePlan search without authorization' do
        metadata do
          id '01'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          description %(
          )
          versions :r4
        end

        @client.set_no_auth
        omit 'Do not test if no bearer token set' if @instance.token.blank?

        search_params = { patient: @instance.patient_id, category: 'assess-plan' }

        reply = get_resource_by_params(versioned_resource_class('CarePlan'), search_params)
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply
      end

      test 'Server returns expected results from CarePlan search by patient+category' do
        metadata do
          id '02'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          description %(
          )
          versions :r4
        end

        search_params = { patient: @instance.patient_id, category: 'assess-plan' }

        reply = get_resource_by_params(versioned_resource_class('CarePlan'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)

        resource_count = reply&.resource&.entry&.length || 0
        @resources_found = true if resource_count.positive?

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        @careplan = reply.try(:resource).try(:entry).try(:first).try(:resource)
        @careplan_ary = reply&.resource&.entry&.map { |entry| entry&.resource }
        save_resource_ids_in_bundle(versioned_resource_class('CarePlan'), reply)
        save_delayed_sequence_references(@careplan)
        validate_search_reply(versioned_resource_class('CarePlan'), reply, search_params)
      end

      test 'Server returns expected results from CarePlan search by patient+category+status' do
        metadata do
          id '03'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          optional
          description %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@careplan.nil?, 'Expected valid CarePlan resource to be present'

        patient_val = @instance.patient_id
        category_val = resolve_element_from_path(@careplan, 'category.coding.code')
        status_val = resolve_element_from_path(@careplan, 'status')
        search_params = { 'patient': patient_val, 'category': category_val, 'status': status_val }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('CarePlan'), search_params)
        validate_search_reply(versioned_resource_class('CarePlan'), reply, search_params)
        assert_response_ok(reply)
      end

      test 'Server returns expected results from CarePlan search by patient+category+status+date' do
        metadata do
          id '04'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          optional
          description %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@careplan.nil?, 'Expected valid CarePlan resource to be present'

        patient_val = @instance.patient_id
        category_val = resolve_element_from_path(@careplan, 'category.coding.code')
        status_val = resolve_element_from_path(@careplan, 'status')
        date_val = resolve_element_from_path(@careplan, 'period.start')
        search_params = { 'patient': patient_val, 'category': category_val, 'status': status_val, 'date': date_val }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('CarePlan'), search_params)
        validate_search_reply(versioned_resource_class('CarePlan'), reply, search_params)
        assert_response_ok(reply)

        ['gt', 'lt', 'le'].each do |comparator|
          comparator_val = date_comparator_value(comparator, date_val)
          comparator_search_params = { 'patient': patient_val, 'category': category_val, 'status': status_val, 'date': comparator_val }
          reply = get_resource_by_params(versioned_resource_class('CarePlan'), comparator_search_params)
          validate_search_reply(versioned_resource_class('CarePlan'), reply, comparator_search_params)
          assert_response_ok(reply)
        end
      end

      test 'Server returns expected results from CarePlan search by patient+category+date' do
        metadata do
          id '05'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          optional
          description %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@careplan.nil?, 'Expected valid CarePlan resource to be present'

        patient_val = @instance.patient_id
        category_val = resolve_element_from_path(@careplan, 'category.coding.code')
        date_val = resolve_element_from_path(@careplan, 'period.start')
        search_params = { 'patient': patient_val, 'category': category_val, 'date': date_val }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('CarePlan'), search_params)
        validate_search_reply(versioned_resource_class('CarePlan'), reply, search_params)
        assert_response_ok(reply)

        ['gt', 'lt', 'le'].each do |comparator|
          comparator_val = date_comparator_value(comparator, date_val)
          comparator_search_params = { 'patient': patient_val, 'category': category_val, 'date': comparator_val }
          reply = get_resource_by_params(versioned_resource_class('CarePlan'), comparator_search_params)
          validate_search_reply(versioned_resource_class('CarePlan'), reply, comparator_search_params)
          assert_response_ok(reply)
        end
      end

      test 'CarePlan read resource supported' do
        metadata do
          id '06'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          description %(
          )
          versions :r4
        end

        skip_if_not_supported(:CarePlan, [:read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_read_reply(@careplan, versioned_resource_class('CarePlan'))
      end

      test 'CarePlan vread resource supported' do
        metadata do
          id '07'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          description %(
          )
          versions :r4
        end

        skip_if_not_supported(:CarePlan, [:vread])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_vread_reply(@careplan, versioned_resource_class('CarePlan'))
      end

      test 'CarePlan history resource supported' do
        metadata do
          id '08'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          description %(
          )
          versions :r4
        end

        skip_if_not_supported(:CarePlan, [:history])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_history_reply(@careplan, versioned_resource_class('CarePlan'))
      end

      test 'CarePlan resources associated with Patient conform to US Core R4 profiles' do
        metadata do
          id '09'
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-careplan'
          description %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        test_resources_against_profile('CarePlan')
      end

      test 'At least one of every must support element is provided in any CarePlan for this patient.' do
        metadata do
          id '10'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/general-guidance.html/#must-support'
          description %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information' unless @careplan_ary&.any?
        must_support_confirmed = {}
        must_support_elements = [
          'CarePlan.text',
          'CarePlan.text.status',
          'CarePlan.status',
          'CarePlan.intent',
          'CarePlan.category',
          'CarePlan.category',
          'CarePlan.subject'
        ]
        must_support_elements.each do |path|
          @careplan_ary&.each do |resource|
            truncated_path = path.gsub('CarePlan.', '')
            must_support_confirmed[path] = true if can_resolve_path(resource, truncated_path)
            break if must_support_confirmed[path]
          end
          resource_count = @careplan_ary.length

          skip "Could not find #{path} in any of the #{resource_count} provided CarePlan resource(s)" unless must_support_confirmed[path]
        end
        @instance.save!
      end

      test 'All references can be resolved' do
        metadata do
          id '11'
          link 'https://www.hl7.org/fhir/DSTU2/references.html'
          description %(
          )
          versions :r4
        end

        skip_if_not_supported(:CarePlan, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_reference_resolutions(@careplan)
      end
    end
  end
end
