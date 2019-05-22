
module Inferno
  module Sequence
    class UsCoreR4PatientSequence < SequenceBase

      group 'US Core R4 Profile Conformance'

      title 'US Core R4 Patient Tests'

      description 'Verify that Patient resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

      test_id_prefix 'Patient' # change me

      requires :token, :patient_id
      conformance_supports :Patient

      
        def validate_resource_item (resource, property, value)
          case property
          
          when '_id'
            assert resource&.id != nil && resource&.id == value, "_id on resource did not match _id requested"
        
          when 'birthdate'
        
          when 'family'
            assert resource&.name&.family != nil && resource&.name&.family == value, "family on resource did not match family requested"
        
          when 'gender'
            assert resource&.gender != nil && resource&.gender == value, "gender on resource did not match gender requested"
        
          when 'given'
            assert resource&.name&.given != nil && resource&.name&.given == value, "given on resource did not match given requested"
        
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
        
        The #{title} Sequence tests `#{title.gsub(/\s+/,"")}` resources associated with the provided patient.  The resources
        returned will be checked for consistency against the [Patient Argonaut Profile](https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-patient)

      )

      @resources_found = false
      
      test 'Server rejects Patient search without authorization' do
        metadata {
          id '1'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
          )
          versions :r4
        }
        
        @client.set_no_auth
        skip 'Could not verify this functionality when bearer token is not set' if @instance.token.blank?

        reply = get_resource_by_params(versioned_resource_class('Patient'), {patient: @instance.patient_id})
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply
  
      end
      
      test 'Server returns expected results from Patient search by _id' do
        metadata {
          id '2'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        }
        
        
        search_params = {'_id': @instance.patient_id}
      
        reply = get_resource_by_params(versioned_resource_class('Patient'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)

        resource_count = reply.try(:resource).try(:entry).try(:length) || 0
        if resource_count > 0
          @resources_found = true
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        @patient = reply.try(:resource).try(:entry).try(:first).try(:resource)
        validate_search_reply(versioned_resource_class('Patient'), reply, search_params)
        save_resource_ids_in_bundle(versioned_resource_class('Patient'), reply)
    
      end
      
      test 'Server returns expected results from Patient search by identifier' do
        metadata {
          id '3'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        }
        
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@patient.nil?, 'Expected valid Patient resource to be present'
        
        identifier_val = @patient&.identifier.first&.value
        search_params = {'identifier': identifier_val}
  
        reply = get_resource_by_params(versioned_resource_class('Patient'), search_params)
        assert_response_ok(reply)
    
      end
      
      test 'Server returns expected results from Patient search by name' do
        metadata {
          id '4'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        }
        
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@patient.nil?, 'Expected valid Patient resource to be present'
        
        name_val = @patient&.name.first&.family
        search_params = {'name': name_val}
  
        reply = get_resource_by_params(versioned_resource_class('Patient'), search_params)
        assert_response_ok(reply)
    
      end
      
      test 'Server returns expected results from Patient search by birthdate+name' do
        metadata {
          id '5'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        }
        
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@patient.nil?, 'Expected valid Patient resource to be present'
        
        birthdate_val = @patient&.birthDate
        name_val = @patient&.name.first&.family
        search_params = {'birthdate': birthdate_val, 'name': name_val}
  
        reply = get_resource_by_params(versioned_resource_class('Patient'), search_params)
        assert_response_ok(reply)
    
      end
      
      test 'Server returns expected results from Patient search by gender+name' do
        metadata {
          id '6'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        }
        
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@patient.nil?, 'Expected valid Patient resource to be present'
        
        gender_val = @patient&.gender
        name_val = @patient&.name.first&.family
        search_params = {'gender': gender_val, 'name': name_val}
  
        reply = get_resource_by_params(versioned_resource_class('Patient'), search_params)
        assert_response_ok(reply)
    
      end
      
      test 'Server returns expected results from Patient search by family+gender' do
        metadata {
          id '7'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        }
        
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@patient.nil?, 'Expected valid Patient resource to be present'
        
        family_val = @patient&.name.first&.family
        gender_val = @patient&.gender
        search_params = {'family': family_val, 'gender': gender_val}
  
        reply = get_resource_by_params(versioned_resource_class('Patient'), search_params)
        assert_response_ok(reply)
    
      end
      
      test 'Server returns expected results from Patient search by birthdate+family' do
        metadata {
          id '8'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        }
        
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@patient.nil?, 'Expected valid Patient resource to be present'
        
        birthdate_val = @patient&.birthDate
        family_val = @patient&.name.first&.family
        search_params = {'birthdate': birthdate_val, 'family': family_val}
  
        reply = get_resource_by_params(versioned_resource_class('Patient'), search_params)
        assert_response_ok(reply)
    
      end
      
      test 'Patient read resource supported' do
        metadata {
          id '9'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        }
        
        skip_if_not_supported(:Patient, [:read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_read_reply(@patient, versioned_resource_class('Patient'))
  
      end
      
      test 'Patient vread resource supported' do
        metadata {
          id '10'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        }
        
        skip_if_not_supported(:Patient, [:vread])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_vread_reply(@patient, versioned_resource_class('Patient'))
  
      end
      
      test 'Patient history resource supported' do
        metadata {
          id '11'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        }
        
        skip_if_not_supported(:Patient, [:history])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_history_reply(@patient, versioned_resource_class('Patient'))
  
      end
      
      test 'Patient resources associated with Patient conform to Argonaut profiles' do
        metadata {
          id '12'
          link ''
          desc %(
          )
          versions :r4
        }
        
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        test_resources_against_profile('Patient')
  
      end
      
      test 'All references can be resolved' do
        metadata {
          id '13'
          link 'https://www.hl7.org/fhir/DSTU2/references.html'
          desc %(
          )
          versions :r4
        }
        
        skip_if_not_supported(:Patient, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_reference_resolutions(@patient)
  
      end
      
    end
  end
end