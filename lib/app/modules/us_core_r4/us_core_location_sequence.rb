
module Inferno
  module Sequence
    class UsCoreR4LocationSequence < SequenceBase

      group 'US Core R4 Profile Conformance'

      title 'US Core R4 Location Tests'

      description 'Verify that Location resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

      test_id_prefix 'Location' # change me

      requires :token, :patient_id
      conformance_supports :Location

      

      details %(
      )

      @resources_found = false
      
      test 'Server rejects Location search without authorization' do
        metadata {
          id '1'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
          )
          versions :r4
        }
        
        @client.set_no_auth
        skip 'Could not verify this functionality when bearer token is not set' if @instance.token.blank?

        reply = get_resource_by_params(versioned_resource_class('Location'), {patient: @instance.patient_id})
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply
  
      end
      
      test 'Server returns expected results from Location search by name' do
        metadata {
          id '2'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        }
        
        search_params = {patient: @instance.patient_id}
        reply = get_resource_by_params(versioned_resource_class('Location'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_search_reply(versioned_resource_class('Location'), reply, search_params)
  
        resource_count = reply.try(:resource).try(:entry).try(:length) || 0
        if resource_count > 0
          @resources_found = true
        end
        @location = reply.try(:resource).try(:entry).try(:first).try(:resource)
        save_resource_ids_in_bundle(versioned_resource_class('Location'), reply)
    
      end
      
      test 'Server returns expected results from Location search by address' do
        metadata {
          id '3'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        }
        
        search_params = {patient: @instance.patient_id}
        reply = get_resource_by_params(versioned_resource_class('Location'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_search_reply(versioned_resource_class('Location'), reply, search_params)
  
      end
      
      test 'Server returns expected results from Location search by address-city' do
        metadata {
          id '4'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        }
        
        search_params = {patient: @instance.patient_id}
        reply = get_resource_by_params(versioned_resource_class('Location'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_search_reply(versioned_resource_class('Location'), reply, search_params)
  
      end
      
      test 'Server returns expected results from Location search by address-state' do
        metadata {
          id '5'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        }
        
        search_params = {patient: @instance.patient_id}
        reply = get_resource_by_params(versioned_resource_class('Location'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_search_reply(versioned_resource_class('Location'), reply, search_params)
  
      end
      
      test 'Server returns expected results from Location search by address-postalcode' do
        metadata {
          id '6'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        }
        
        search_params = {patient: @instance.patient_id}
        reply = get_resource_by_params(versioned_resource_class('Location'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_search_reply(versioned_resource_class('Location'), reply, search_params)
  
      end
      
      test 'Location read resource supported' do
        metadata {
          id '7'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        }
        
        skip_if_not_supported(:Location, [:read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_read_reply(@location, versioned_resource_class('Location'))
  
      end
      
      test 'Location vread resource supported' do
        metadata {
          id '8'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        }
        
        skip_if_not_supported(:Location, [:vread])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_vread_reply(@location, versioned_resource_class('Location'))
  
      end
      
      test 'Location history resource supported' do
        metadata {
          id '9'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        }
        
        skip_if_not_supported(:Location, [:history])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_history_reply(@location, versioned_resource_class('Location'))
  
      end
      
      test 'Location resources associated with Patient conform to Argonaut profiles' do
        metadata {
          id '10'
          link ''
          desc %(
          )
          versions :r4
        }
        
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        test_resources_against_profile('Location')
  
      end
      
      test 'All references can be resolved' do
        metadata {
          id '11'
          link 'https://www.hl7.org/fhir/DSTU2/references.html'
          desc %(
          )
          versions :r4
        }
        
        skip_if_not_supported(:Location, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_reference_resolutions(@location)
  
      end
      
    end
  end
end