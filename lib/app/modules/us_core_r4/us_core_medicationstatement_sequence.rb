
module Inferno
  module Sequence
    class UsCoreR4MedicationstatementSequence < SequenceBase

      group 'US Core R4 Profile Conformance'

      title 'US Core R4 MedicationStatement Tests'

      description 'Verify that MedicationStatement resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

      test_id_prefix 'MedicationStatement' # change me

      requires :token, :patient_id
      conformance_supports :MedicationStatement

      
        def validate_resource_item (resource, property, value)
          case property
          
          when 'patient'
            assert (resource.patient && resource.patient.reference.include?(value)), "patient on resource does not match patient requested"
        
          end
        end
    

      details %(
      )

      @resources_found = false
      
      test 'Server rejects MedicationStatement search without authorization' do
        metadata {
          id '1'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
          )
          versions :r4
        }
        
        @client.set_no_auth
        skip 'Could not verify this functionality when bearer token is not set' if @instance.token.blank?

        reply = get_resource_by_params(versioned_resource_class('MedicationStatement'), {patient: @instance.patient_id})
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply
  
      end
      
      test 'Server returns expected results from MedicationStatement search by patient' do
        metadata {
          id '2'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        }
        
        search_params = {patient: @instance.patient_id}
        reply = get_resource_by_params(versioned_resource_class('MedicationStatement'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_search_reply(versioned_resource_class('MedicationStatement'), reply, search_params)
  
        resource_count = reply.try(:resource).try(:entry).try(:length) || 0
        if resource_count > 0
          @resources_found = true
        end
        @medicationstatement = reply.try(:resource).try(:entry).try(:first).try(:resource)
        save_resource_ids_in_bundle(versioned_resource_class('MedicationStatement'), reply)
    
      end
      
      test 'Server returns expected results from MedicationStatement search by patient + effective' do
        metadata {
          id '3'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        }
        
        
        patient_val = @instance.patient_id
        effective_val = @medicationstatement.try(:effectiveDateTime)
        search_params = {'patient': patient_val, 'effective': effective_val}
  
        reply = get_resource_by_params(versioned_resource_class('MedicationStatement'), search_params)
        validate_search_reply(versioned_resource_class('MedicationStatement'), reply, search_params)
  
      end
      
      test 'Server returns expected results from MedicationStatement search by patient + status' do
        metadata {
          id '4'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        }
        
        
        patient_val = @instance.patient_id
        status_val = @medicationstatement.try(:status)
        search_params = {'patient': patient_val, 'status': status_val}
  
        reply = get_resource_by_params(versioned_resource_class('MedicationStatement'), search_params)
        validate_search_reply(versioned_resource_class('MedicationStatement'), reply, search_params)
  
      end
      
      test 'MedicationStatement read resource supported' do
        metadata {
          id '5'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        }
        
        skip_if_not_supported(:MedicationStatement, [:read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_read_reply(@medicationstatement, versioned_resource_class('MedicationStatement'))
  
      end
      
      test 'MedicationStatement vread resource supported' do
        metadata {
          id '6'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        }
        
        skip_if_not_supported(:MedicationStatement, [:vread])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_vread_reply(@medicationstatement, versioned_resource_class('MedicationStatement'))
  
      end
      
      test 'MedicationStatement history resource supported' do
        metadata {
          id '7'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        }
        
        skip_if_not_supported(:MedicationStatement, [:history])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_history_reply(@medicationstatement, versioned_resource_class('MedicationStatement'))
  
      end
      
      test 'MedicationStatement resources associated with Patient conform to Argonaut profiles' do
        metadata {
          id '8'
          link ''
          desc %(
          )
          versions :r4
        }
        
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        test_resources_against_profile('MedicationStatement')
  
      end
      
      test 'All references can be resolved' do
        metadata {
          id '9'
          link 'https://www.hl7.org/fhir/DSTU2/references.html'
          desc %(
          )
          versions :r4
        }
        
        skip_if_not_supported(:MedicationStatement, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_reference_resolutions(@medicationstatement)
  
      end
      
    end
  end
end