
module Inferno
  module Sequence
    class UsCoreR4PractitionerSequence < SequenceBase

      group 'US Core R4 Profile Conformance'

      title 'US Core R4 Practitioner Tests'

      description 'Verify that Practitioner resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

      test_id_prefix 'Practitioner' # change me

      requires :token, :patient_id
      conformance_supports :Practitioner

      
        def validate_resource_item (resource, property, value)
          case property
          
            when 'name'
              found = resource.name.any? do |name|
                name&.text&.include?(value) ||
                  name&.family.include?(value) || 
                  name&.given.any{|given| given&.include?(value)} ||
                  name&.prefix.any{|prefix| prefix&.include?(value)} ||
                  name&.suffix.any{|suffix| suffix&.include?(value)}
              end
              assert found, "name on resource does not match name requested"
          
          end
        end
    

      details %(
      )

      @resources_found = false
      
      test 'Server rejects Practitioner search without authorization' do
        metadata {
          id '1'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
          )
          versions :r4
        }
        
        @client.set_no_auth
        skip 'Could not verify this functionality when bearer token is not set' if @instance.token.blank?

        reply = get_resource_by_params(versioned_resource_class('Practitioner'), {patient: @instance.patient_id})
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply
  
      end
      
      test 'Server returns expected results from Practitioner search by name' do
        metadata {
          id '2'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        }
        
        search_params = {patient: @instance.patient_id}
        reply = get_resource_by_params(versioned_resource_class('Practitioner'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_search_reply(versioned_resource_class('Practitioner'), reply, search_params)
  
        resource_count = reply.try(:resource).try(:entry).try(:length) || 0
        if resource_count > 0
          @resources_found = true
        end
        @practitioner = reply.try(:resource).try(:entry).try(:first).try(:resource)
        save_resource_ids_in_bundle(versioned_resource_class('Practitioner'), reply)
    
      end
      
      test 'Server returns expected results from Practitioner search by identifier' do
        metadata {
          id '3'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        }
        
        search_params = {patient: @instance.patient_id}
        reply = get_resource_by_params(versioned_resource_class('Practitioner'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_search_reply(versioned_resource_class('Practitioner'), reply, search_params)
  
      end
      
      test 'Practitioner read resource supported' do
        metadata {
          id '4'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        }
        
        skip_if_not_supported(:Practitioner, [:read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_read_reply(@practitioner, versioned_resource_class('Practitioner'))
  
      end
      
      test 'Practitioner vread resource supported' do
        metadata {
          id '5'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        }
        
        skip_if_not_supported(:Practitioner, [:vread])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_vread_reply(@practitioner, versioned_resource_class('Practitioner'))
  
      end
      
      test 'Practitioner history resource supported' do
        metadata {
          id '6'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        }
        
        skip_if_not_supported(:Practitioner, [:history])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_history_reply(@practitioner, versioned_resource_class('Practitioner'))
  
      end
      
      test 'Practitioner resources associated with Patient conform to Argonaut profiles' do
        metadata {
          id '7'
          link ''
          desc %(
          )
          versions :r4
        }
        
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        test_resources_against_profile('Practitioner')
  
      end
      
      test 'All references can be resolved' do
        metadata {
          id '8'
          link 'https://www.hl7.org/fhir/DSTU2/references.html'
          desc %(
          )
          versions :r4
        }
        
        skip_if_not_supported(:Practitioner, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_reference_resolutions(@practitioner)
  
      end
      
    end
  end
end