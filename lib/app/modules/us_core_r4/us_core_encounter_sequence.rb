
module Inferno
  module Sequence
    class UsCoreR4EncounterSequence < SequenceBase

      group 'US Core R4 Profile Conformance'

      title 'US Core R4 Encounter Tests'

      description 'Verify that Encounter resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

      test_id_prefix 'Encounter' # change me

      requires :token, :patient_id
      conformance_supports :Encounter

      
        def validate_resource_item (resource, property, value)
          case property
          
          when 'patient'
            assert (resource.patient && resource.patient.reference.include?(value)), "patient on resource does not match patient requested"
        
          when 'type'
            codings = resource.try(:type).try(:coding)
            assert !codings.nil?, "type on resource did not match type requested"
            assert codings.any? {|coding| !coding.try(:code).nil? && coding.try(:code) == value}, "type on resource did not match type requested"
        
          end
        end
    

      details %(
      )

      @resources_found = false
      
      test 'Server rejects Encounter search without authorization' do
        metadata {
          id '1'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
          )
          versions :r4
        }
        
        @client.set_no_auth
        skip 'Could not verify this functionality when bearer token is not set' if @instance.token.blank?

        reply = get_resource_by_params(versioned_resource_class('Encounter'), {patient: @instance.patient_id})
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply
  
      end
      
      test 'Server returns expected results from Encounter search by _id' do
        metadata {
          id '2'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        }
        
        search_params = {patient: @instance.patient_id}
        reply = get_resource_by_params(versioned_resource_class('Encounter'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_search_reply(versioned_resource_class('Encounter'), reply, search_params)
  
        resource_count = reply.try(:resource).try(:entry).try(:length) || 0
        if resource_count > 0
          @resources_found = true
        end
        @encounter = reply.try(:resource).try(:entry).try(:first).try(:resource)
        save_resource_ids_in_bundle(versioned_resource_class('Encounter'), reply)
    
      end
      
      test 'Server returns expected results from Encounter search by patient' do
        metadata {
          id '3'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        }
        
        search_params = {patient: @instance.patient_id}
        reply = get_resource_by_params(versioned_resource_class('Encounter'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_search_reply(versioned_resource_class('Encounter'), reply, search_params)
  
      end
      
      test 'Server returns expected results from Encounter search by identifier' do
        metadata {
          id '4'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        }
        
        search_params = {patient: @instance.patient_id}
        reply = get_resource_by_params(versioned_resource_class('Encounter'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_search_reply(versioned_resource_class('Encounter'), reply, search_params)
  
      end
      
      test 'Server returns expected results from Encounter search by date + patient' do
        metadata {
          id '5'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        }
        
        
        date_val = @encounter.try(:period)
        patient_val = @instance.patient_id
        search_params = {'date': date_val, 'patient': patient_val}
  
        reply = get_resource_by_params(versioned_resource_class('Encounter'), search_params)
        validate_search_reply(versioned_resource_class('Encounter'), reply, search_params)
  
      end
      
      test 'Server returns expected results from Encounter search by patient + status' do
        metadata {
          id '6'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        }
        
        
        patient_val = @instance.patient_id
        status_val = @encounter.try(:status)
        search_params = {'patient': patient_val, 'status': status_val}
  
        reply = get_resource_by_params(versioned_resource_class('Encounter'), search_params)
        validate_search_reply(versioned_resource_class('Encounter'), reply, search_params)
  
      end
      
      test 'Server returns expected results from Encounter search by class + patient' do
        metadata {
          id '7'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        }
        
        
        class_val = @encounter.try(:class)
        patient_val = @instance.patient_id
        search_params = {'class': class_val, 'patient': patient_val}
  
        reply = get_resource_by_params(versioned_resource_class('Encounter'), search_params)
        validate_search_reply(versioned_resource_class('Encounter'), reply, search_params)
  
      end
      
      test 'Server returns expected results from Encounter search by patient + type' do
        metadata {
          id '8'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        }
        
        
        patient_val = @instance.patient_id
        type_val = @encounter.try(:type).try(:coding).try(:first).try(:code)
        search_params = {'patient': patient_val, 'type': type_val}
  
        reply = get_resource_by_params(versioned_resource_class('Encounter'), search_params)
        validate_search_reply(versioned_resource_class('Encounter'), reply, search_params)
  
      end
      
      test 'Encounter read resource supported' do
        metadata {
          id '9'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        }
        
        skip_if_not_supported(:Encounter, [:read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_read_reply(@encounter, versioned_resource_class('Encounter'))
  
      end
      
      test 'Encounter vread resource supported' do
        metadata {
          id '10'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        }
        
        skip_if_not_supported(:Encounter, [:vread])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_vread_reply(@encounter, versioned_resource_class('Encounter'))
  
      end
      
      test 'Encounter history resource supported' do
        metadata {
          id '11'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        }
        
        skip_if_not_supported(:Encounter, [:history])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_history_reply(@encounter, versioned_resource_class('Encounter'))
  
      end
      
      test 'Encounter resources associated with Patient conform to Argonaut profiles' do
        metadata {
          id '12'
          link ''
          desc %(
          )
          versions :r4
        }
        
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        test_resources_against_profile('Encounter')
  
      end
      
      test 'All references can be resolved' do
        metadata {
          id '13'
          link 'https://www.hl7.org/fhir/DSTU2/references.html'
          desc %(
          )
          versions :r4
        }
        
        skip_if_not_supported(:Encounter, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_reference_resolutions(@encounter)
  
      end
      
    end
  end
end