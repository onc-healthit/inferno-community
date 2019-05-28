
module Inferno
  module Sequence
    class UsCoreR4CareteamSequence < SequenceBase

      group 'US Core R4 Profile Conformance'

      title 'US Core R4 Careteam Tests'

      description 'Verify that CareTeam resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

      test_id_prefix 'CareTeam' # change me

      requires :token, :patient_id
      conformance_supports :CareTeam

      
        def validate_resource_item (resource, property, value)
          case property
          
          when 'patient'
            assert (resource&.subject && resource.subject.reference.include?(value)), "patient on resource does not match patient requested"
        
          when 'status'
            assert resource&.status != nil && resource&.status == value, "status on resource did not match status requested"
        
          end
        end
    

      details %(
        
        The #{title} Sequence tests `#{title.gsub(/\s+/,"")}` resources associated with the provided patient.  The resources
        returned will be checked for consistency against the [Careteam Argonaut Profile](https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-careteam)

      )

      @resources_found = false
      
      test 'Server rejects CareTeam search without authorization' do
        metadata {
          id '01'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
          )
          versions :r4
        }
        
        @client.set_no_auth
        skip 'Could not verify this functionality when bearer token is not set' if @instance.token.blank?

        reply = get_resource_by_params(versioned_resource_class('CareTeam'), {patient: @instance.patient_id})
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply
  
      end
      
      test 'Server returns expected results from CareTeam search by patient+status' do
        metadata {
          id '02'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        }
        
        
        search_params = {patient: @instance.patient_id, status: "active"}
      
        reply = get_resource_by_params(versioned_resource_class('CareTeam'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)

        resource_count = reply.try(:resource).try(:entry).try(:length) || 0
        if resource_count > 0
          @resources_found = true
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        @careteam = reply.try(:resource).try(:entry).try(:first).try(:resource)
        validate_search_reply(versioned_resource_class('CareTeam'), reply, search_params)
        save_resource_ids_in_bundle(versioned_resource_class('CareTeam'), reply)
    
      end
      
      test 'CareTeam read resource supported' do
        metadata {
          id '03'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        }
        
        skip_if_not_supported(:CareTeam, [:read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_read_reply(@careteam, versioned_resource_class('CareTeam'))
  
      end
      
      test 'CareTeam vread resource supported' do
        metadata {
          id '04'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        }
        
        skip_if_not_supported(:CareTeam, [:vread])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_vread_reply(@careteam, versioned_resource_class('CareTeam'))
  
      end
      
      test 'CareTeam history resource supported' do
        metadata {
          id '05'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        }
        
        skip_if_not_supported(:CareTeam, [:history])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_history_reply(@careteam, versioned_resource_class('CareTeam'))
  
      end
      
      test 'CareTeam resources associated with Patient conform to Argonaut profiles' do
        metadata {
          id '06'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-careteam.json'
          desc %(
          )
          versions :r4
        }
        
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        test_resources_against_profile('CareTeam')
  
      end
      
      test 'All references can be resolved' do
        metadata {
          id '07'
          link 'https://www.hl7.org/fhir/DSTU2/references.html'
          desc %(
          )
          versions :r4
        }
        
        skip_if_not_supported(:CareTeam, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_reference_resolutions(@careteam)
  
      end
      
    end
  end
end