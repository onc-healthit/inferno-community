# frozen_string_literal: true

module Inferno
  module Sequence
    class UsCoreR4DocumentreferenceSequence < SequenceBase
      group 'US Core R4 Profile Conformance'

      title 'Documentreference Tests'

      description 'Verify that DocumentReference resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

      test_id_prefix 'DocumentReference' # change me

      requires :token, :patient_id
      conformance_supports :DocumentReference
      
      def validate_resource_item(resource, property, value)
        case property
          
        when 'patient'
          assert (resource&.subject && resource.subject.reference.include?(value)), 'patient on resource does not match patient requested'

        when '_id'
          assert resource&.id == value, '_id on resource did not match _id requested'

        when 'status'
          assert resource&.status == value, 'status on resource did not match status requested'

        when 'category'
          codings = resource&.category.first&.coding
          assert !codings.nil?, 'category on resource did not match category requested'
          assert codings.any? { |coding| !coding.try(:code).nil? && coding.try(:code) == value}, 'category on resource did not match category requested'

        when 'type'
          codings = resource&.type&.coding
          assert !codings.nil?, 'type on resource did not match type requested'
          assert codings.any? { |coding| !coding.try(:code).nil? && coding.try(:code) == value}, 'type on resource did not match type requested'

        when 'date'

        when 'period'

        end
      end
    

      details %(

        The #{title} Sequence tests `#{title.gsub(/\s+/,'')}` resources associated with the provided patient.  The resources
        returned will be checked for consistency against the [Documentreference Argonaut Profile](https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-documentreference)

      )

      @resources_found = false

      test 'Server rejects DocumentReference search without authorization' do
        metadata do
          id '01'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
          )
          versions :r4
        end

        @client.set_no_auth
        skip 'Could not verify this functionality when bearer token is not set' if @instance.token.blank?

        reply = get_resource_by_params(versioned_resource_class('DocumentReference'), patient: @instance.patient_id)
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply

      end

      test 'Server returns expected results from DocumentReference search by patient' do
        metadata do
          id '02'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        
        patient_val = @instance.patient_id
        search_params = { 'patient': patient_val }

        reply = get_resource_by_params(versioned_resource_class('DocumentReference'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)

        resource_count = reply.try(:resource).try(:entry).try(:length) || 0
        @resources_found = true if resource_count.positive?

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        @documentreference = reply.try(:resource).try(:entry).try(:first).try(:resource)
        validate_search_reply(versioned_resource_class('DocumentReference'), reply, search_params)
        save_resource_ids_in_bundle(versioned_resource_class('DocumentReference'), reply)
      
      end

      test 'Server returns expected results from DocumentReference search by _id' do
        metadata do
          id '03'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@documentreference.nil?, 'Expected valid DocumentReference resource to be present'
        
        _id_val = @documentreference&.id
        search_params = { '_id': _id_val }

        reply = get_resource_by_params(versioned_resource_class('DocumentReference'), search_params)
        assert_response_ok(reply)
      end

      test 'Server returns expected results from DocumentReference search by patient+category' do
        metadata do
          id '04'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@documentreference.nil?, 'Expected valid DocumentReference resource to be present'
        
        patient_val = @instance.patient_id
        category_val = @documentreference&.category&.first&.coding&.first&.code
        search_params = { 'patient': patient_val, 'category': category_val }

        reply = get_resource_by_params(versioned_resource_class('DocumentReference'), search_params)
        assert_response_ok(reply)
      end

      test 'Server returns expected results from DocumentReference search by patient+category+date' do
        metadata do
          id '05'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@documentreference.nil?, 'Expected valid DocumentReference resource to be present'
        
        patient_val = @instance.patient_id
        category_val = @documentreference&.category&.first&.coding&.first&.code
        date_val = @documentreference&.date
        search_params = { 'patient': patient_val, 'category': category_val, 'date': date_val }

        reply = get_resource_by_params(versioned_resource_class('DocumentReference'), search_params)
        assert_response_ok(reply)
      end

      test 'Server returns expected results from DocumentReference search by patient+type' do
        metadata do
          id '06'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@documentreference.nil?, 'Expected valid DocumentReference resource to be present'
        
        patient_val = @instance.patient_id
        type_val = @documentreference&.type&.coding&.first&.code
        search_params = { 'patient': patient_val, 'type': type_val }

        reply = get_resource_by_params(versioned_resource_class('DocumentReference'), search_params)
        assert_response_ok(reply)
      end

      test 'Server returns expected results from DocumentReference search by patient+status' do
        metadata do
          id '07'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@documentreference.nil?, 'Expected valid DocumentReference resource to be present'
        
        patient_val = @instance.patient_id
        status_val = @documentreference&.status
        search_params = { 'patient': patient_val, 'status': status_val }

        reply = get_resource_by_params(versioned_resource_class('DocumentReference'), search_params)
        assert_response_ok(reply)
      end

      test 'Server returns expected results from DocumentReference search by patient+type+period' do
        metadata do
          id '08'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@documentreference.nil?, 'Expected valid DocumentReference resource to be present'
        
        patient_val = @instance.patient_id
        type_val = @documentreference&.type&.coding&.first&.code
        period_val = @documentreference&.context&.period&.start
        search_params = { 'patient': patient_val, 'type': type_val, 'period': period_val }

        reply = get_resource_by_params(versioned_resource_class('DocumentReference'), search_params)
        assert_response_ok(reply)
      end

      test 'DocumentReference create resource supported' do
        metadata do
          id '09'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:DocumentReference, [:create])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_create_reply(@documentreference, versioned_resource_class('DocumentReference'))
  
      end

      test 'DocumentReference read resource supported' do
        metadata do
          id '10'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:DocumentReference, [:read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_read_reply(@documentreference, versioned_resource_class('DocumentReference'))
  
      end

      test 'DocumentReference vread resource supported' do
        metadata do
          id '11'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:DocumentReference, [:vread])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_vread_reply(@documentreference, versioned_resource_class('DocumentReference'))
  
      end

      test 'DocumentReference history resource supported' do
        metadata do
          id '12'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:DocumentReference, [:history])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_history_reply(@documentreference, versioned_resource_class('DocumentReference'))
  
      end

      test 'DocumentReference resources associated with Patient conform to Argonaut profiles' do
        metadata do
          id '13'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-documentreference.json'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        test_resources_against_profile('DocumentReference')
  
      end

      test 'All references can be resolved' do
        metadata do
          id '14'
          link 'https://www.hl7.org/fhir/DSTU2/references.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:DocumentReference, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_reference_resolutions(@documentreference)
      end
    end
  end
end