# frozen_string_literal: true

module Inferno
  module Sequence
    class UsCoreR4CareplanSequence < SequenceBase
      group 'US Core R4 Profile Conformance'

      title 'US Core R4 Careplan Tests'

      description 'Verify that CarePlan resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

      test_id_prefix 'CarePlan' # change me

      requires :token, :patient_id
      conformance_supports :CarePlan

      def validate_resource_item(resource, property, value)
        case property

        when 'patient'
          assert (resource&.subject && resource.subject.reference.include?(value)), 'patient on resource does not match patient requested'

        when 'category'
          codings = resource&.category.first&.coding
          assert !codings.nil?, 'category on resource did not match category requested'
          assert codings.any? { |coding| !coding.try(:code).nil? && coding.try(:code) == value }, 'category on resource did not match category requested'

        when 'date'

        when 'status'
          assert !resource&.status.nil? && resource&.status == value, 'status on resource did not match status requested'

        end
      end

      details %(

        The #{title} Sequence tests `#{title.gsub(/\s+/, '')}` resources associated with the provided patient.  The resources
        returned will be checked for consistency against the [Careplan Argonaut Profile](https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-careplan)

      )

      @resources_found = false

      test 'Server rejects CarePlan search without authorization' do
        metadata do
          id '01'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
          )
          versions :r4
        end

        @client.set_no_auth
        skip 'Could not verify this functionality when bearer token is not set' if @instance.token.blank?

        reply = get_resource_by_params(versioned_resource_class('CarePlan'), patient: @instance.patient_id)
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply
      end

      test 'Server returns expected results from CarePlan search by patient+category' do
        metadata do
          id '02'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        search_params = { patient: @instance.patient_id, category: 'assess-plan' }

        reply = get_resource_by_params(versioned_resource_class('CarePlan'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)

        resource_count = reply.try(:resource).try(:entry).try(:length) || 0
        @resources_found = true if resource_count > 0

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        @careplan = reply.try(:resource).try(:entry).try(:first).try(:resource)
        validate_search_reply(versioned_resource_class('CarePlan'), reply, search_params)
        save_resource_ids_in_bundle(versioned_resource_class('CarePlan'), reply)
      end

      test 'Server returns expected results from CarePlan search by patient+category+status' do
        metadata do
          id '03'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@careplan.nil?, 'Expected valid CarePlan resource to be present'

        patient_val = @instance.patient_id
        category_val = @careplan&.category.first&.coding&.first&.code
        status_val = @careplan&.status
        search_params = { 'patient': patient_val, 'category': category_val, 'status': status_val }

        reply = get_resource_by_params(versioned_resource_class('CarePlan'), search_params)
        assert_response_ok(reply)
      end

      test 'Server returns expected results from CarePlan search by patient+category+status+date' do
        metadata do
          id '04'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@careplan.nil?, 'Expected valid CarePlan resource to be present'

        patient_val = @instance.patient_id
        category_val = @careplan&.category.first&.coding&.first&.code
        status_val = @careplan&.status
        date_val = @careplan&.period&.start
        search_params = { 'patient': patient_val, 'category': category_val, 'status': status_val, 'date': date_val }

        reply = get_resource_by_params(versioned_resource_class('CarePlan'), search_params)
        assert_response_ok(reply)
      end

      test 'Server returns expected results from CarePlan search by patient+category+date' do
        metadata do
          id '05'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@careplan.nil?, 'Expected valid CarePlan resource to be present'

        patient_val = @instance.patient_id
        category_val = @careplan&.category.first&.coding&.first&.code
        date_val = @careplan&.period&.start
        search_params = { 'patient': patient_val, 'category': category_val, 'date': date_val }

        reply = get_resource_by_params(versioned_resource_class('CarePlan'), search_params)
        assert_response_ok(reply)
      end

      test 'CarePlan read resource supported' do
        metadata do
          id '06'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
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
          desc %(
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
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:CarePlan, [:history])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_history_reply(@careplan, versioned_resource_class('CarePlan'))
      end

      test 'CarePlan resources associated with Patient conform to Argonaut profiles' do
        metadata do
          id '09'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-careplan.json'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        test_resources_against_profile('CarePlan')
      end

      test 'All references can be resolved' do
        metadata do
          id '10'
          link 'https://www.hl7.org/fhir/DSTU2/references.html'
          desc %(
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
