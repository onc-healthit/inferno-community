# frozen_string_literal: true
module Inferno
  module Sequence
    class UsCoreR4ProcedureSequence < SequenceBase

      group 'US Core R4 Profile Conformance'

      title 'Procedure Tests'

      description 'Verify that Procedure resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

      test_id_prefix 'Procedure' # change me

      requires :token, :patient_id
      conformance_supports :Procedure

      
      def validate_resource_item (resource, property, value)
        case property
          
        when 'patient'
          assert (resource&.subject && resource.subject.reference.include?(value)), 'patient on resource does not match patient requested'
      
        when 'status'
          assert resource&.status == value, 'status on resource did not match status requested'
      
        when 'date'
      
        when 'code'
          codings = resource&.code&.coding
          assert !codings.nil?, 'code on resource did not match code requested'
          assert codings.any? { |coding| !coding.try(:code).nil? && coding.try(:code) == value}, 'code on resource did not match code requested'
      
        end
      end
    

      details %(
        
        The #{title} Sequence tests `#{title.gsub(/\s+/,'')}` resources associated with the provided patient.  The resources
        returned will be checked for consistency against the [Procedure Argonaut Profile](https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-procedure)

      )

      @resources_found = false
      
      test 'Server rejects Procedure search without authorization' do
        metadata do
          id '01'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
          )
          versions :r4
        end
        
        @client.set_no_auth
        skip 'Could not verify this functionality when bearer token is not set' if @instance.token.blank?

        reply = get_resource_by_params(versioned_resource_class('Procedure'), patient: @instance.patient_id)
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply
  
      end
      
      test 'Server returns expected results from Procedure search by patient' do
        metadata do
          id '02'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end
        
        
        patient_val = @instance.patient_id
        search_params = { 'patient': patient_val }
  
        reply = get_resource_by_params(versioned_resource_class('Procedure'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)

        resource_count = reply.try(:resource).try(:entry).try(:length) || 0
        if resource_count > 0
          @resources_found = true
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        @procedure = reply.try(:resource).try(:entry).try(:first).try(:resource)
        validate_search_reply(versioned_resource_class('Procedure'), reply, search_params)
        save_resource_ids_in_bundle(versioned_resource_class('Procedure'), reply)
      
      end
      
      test 'Server returns expected results from Procedure search by patient+date' do
        metadata do
          id '03'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end
        
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@procedure.nil?, 'Expected valid Procedure resource to be present'
        
        patient_val = @instance.patient_id
        date_val = @procedure&.occurrenceDateTime
        search_params = { 'patient': patient_val, 'date': date_val }
  
        reply = get_resource_by_params(versioned_resource_class('Procedure'), search_params)
        assert_response_ok(reply)
      
      end
      
      test 'Server returns expected results from Procedure search by patient+code+date' do
        metadata do
          id '04'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end
        
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@procedure.nil?, 'Expected valid Procedure resource to be present'
        
        patient_val = @instance.patient_id
        code_val = @procedure&.code&.coding&.first&.code
        date_val = @procedure&.occurrenceDateTime
        search_params = { 'patient': patient_val, 'code': code_val, 'date': date_val }
  
        reply = get_resource_by_params(versioned_resource_class('Procedure'), search_params)
        assert_response_ok(reply)
      
      end
      
      test 'Server returns expected results from Procedure search by patient+status' do
        metadata do
          id '05'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end
        
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@procedure.nil?, 'Expected valid Procedure resource to be present'
        
        patient_val = @instance.patient_id
        status_val = @procedure&.status
        search_params = { 'patient': patient_val, 'status': status_val }
  
        reply = get_resource_by_params(versioned_resource_class('Procedure'), search_params)
        assert_response_ok(reply)
      
      end
      
      test 'Procedure read resource supported' do
        metadata do
          id '06'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end
        
        skip_if_not_supported(:Procedure, [:read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_read_reply(@procedure, versioned_resource_class('Procedure'))
  
      end
      
      test 'Procedure vread resource supported' do
        metadata do
          id '07'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end
        
        skip_if_not_supported(:Procedure, [:vread])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_vread_reply(@procedure, versioned_resource_class('Procedure'))
  
      end
      
      test 'Procedure history resource supported' do
        metadata do
          id '08'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end
        
        skip_if_not_supported(:Procedure, [:history])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_history_reply(@procedure, versioned_resource_class('Procedure'))
  
      end
      
      test 'Procedure resources associated with Patient conform to Argonaut profiles' do
        metadata do
          id '09'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-procedure.json'
          desc %(
          )
          versions :r4
        end
        
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        test_resources_against_profile('Procedure')
  
      end
      
      test 'All references can be resolved' do
        metadata do
          id '10'
          link 'https://www.hl7.org/fhir/DSTU2/references.html'
          desc %(
          )
          versions :r4
        end
        
        skip_if_not_supported(:Procedure, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_reference_resolutions(@procedure)
  
      end
      
    end
  end
end