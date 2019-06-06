# frozen_string_literal: true
module Inferno
  module Sequence
    class UsCoreR4DeviceSequence < SequenceBase

      group 'US Core R4 Profile Conformance'

      title 'Device Tests'

      description 'Verify that Device resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

      test_id_prefix 'Device' # change me

      requires :token, :patient_id
      conformance_supports :Device

      
      def validate_resource_item (resource, property, value)
        case property
          
        when 'patient'
          assert (resource&.patient && resource.patient.reference.include?(value)), 'patient on resource does not match patient requested'
      
        when 'type'
          codings = resource&.type&.coding
          assert !codings.nil?, 'type on resource did not match type requested'
          assert codings.any? { |coding| !coding.try(:code).nil? && coding.try(:code) == value}, 'type on resource did not match type requested'
      
        end
      end
    

      details %(
        
        The #{title} Sequence tests `#{title.gsub(/\s+/,'')}` resources associated with the provided patient.  The resources
        returned will be checked for consistency against the [Device Argonaut Profile](https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-device)

      )

      @resources_found = false
      
      test 'Server rejects Device search without authorization' do
        metadata do
          id '01'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
          )
          versions :r4
        end
        
        @client.set_no_auth
        skip 'Could not verify this functionality when bearer token is not set' if @instance.token.blank?

        reply = get_resource_by_params(versioned_resource_class('Device'), patient: @instance.patient_id)
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply
  
      end
      
      test 'Server returns expected results from Device search by patient' do
        metadata do
          id '02'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end
        
        
        patient_val = @instance.patient_id
        search_params = { 'patient': patient_val }
  
        reply = get_resource_by_params(versioned_resource_class('Device'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)

        resource_count = reply.try(:resource).try(:entry).try(:length) || 0
        if resource_count > 0
          @resources_found = true
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        @device = reply.try(:resource).try(:entry).try(:first).try(:resource)
        validate_search_reply(versioned_resource_class('Device'), reply, search_params)
        save_resource_ids_in_bundle(versioned_resource_class('Device'), reply)
      
      end
      
      test 'Server returns expected results from Device search by patient+type' do
        metadata do
          id '03'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end
        
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@device.nil?, 'Expected valid Device resource to be present'
        
        patient_val = @instance.patient_id
        type_val = @device&.type&.coding&.first&.code
        search_params = { 'patient': patient_val, 'type': type_val }
  
        reply = get_resource_by_params(versioned_resource_class('Device'), search_params)
        assert_response_ok(reply)
      
      end
      
      test 'Device read resource supported' do
        metadata do
          id '04'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end
        
        skip_if_not_supported(:Device, [:read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_read_reply(@device, versioned_resource_class('Device'))
  
      end
      
      test 'Device vread resource supported' do
        metadata do
          id '05'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end
        
        skip_if_not_supported(:Device, [:vread])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_vread_reply(@device, versioned_resource_class('Device'))
  
      end
      
      test 'Device history resource supported' do
        metadata do
          id '06'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end
        
        skip_if_not_supported(:Device, [:history])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_history_reply(@device, versioned_resource_class('Device'))
  
      end
      
      test 'Device resources associated with Patient conform to Argonaut profiles' do
        metadata do
          id '07'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-device.json'
          desc %(
          )
          versions :r4
        end
        
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        test_resources_against_profile('Device')
  
      end
      
      test 'All references can be resolved' do
        metadata do
          id '08'
          link 'https://www.hl7.org/fhir/DSTU2/references.html'
          desc %(
          )
          versions :r4
        end
        
        skip_if_not_supported(:Device, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_reference_resolutions(@device)
  
      end
      
    end
  end
end