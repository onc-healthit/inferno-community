# frozen_string_literal: true

module Inferno
  module Sequence
    class UsCoreR4AllergyintoleranceSequence < SequenceBase
      group 'US Core R4 Profile Conformance'

      title 'Allergyintolerance Tests'

      description 'Verify that AllergyIntolerance resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

      test_id_prefix 'AllergyIntolerance' # change me

      requires :token, :patient_id
      conformance_supports :AllergyIntolerance
      
      def validate_resource_item(resource, property, value)
        case property
          
        when 'patient'
          assert (resource&.patient && resource.patient.reference.include?(value)), 'patient on resource does not match patient requested'

        when 'clinical-status'
          codings = resource&.clinicalStatus&.coding
          assert !codings.nil?, 'clinical-status on resource did not match clinical-status requested'
          assert codings.any? { |coding| !coding.try(:code).nil? && coding.try(:code) == value}, 'clinical-status on resource did not match clinical-status requested'

        end
      end
    

      details %(

        The #{title} Sequence tests `#{title.gsub(/\s+/,'')}` resources associated with the provided patient.  The resources
        returned will be checked for consistency against the [Allergyintolerance Argonaut Profile](https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-allergyintolerance)

      )

      @resources_found = false

      test 'Server rejects AllergyIntolerance search without authorization' do
        metadata do
          id '01'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
          )
          versions :r4
        end

        @client.set_no_auth
        skip 'Could not verify this functionality when bearer token is not set' if @instance.token.blank?

        reply = get_resource_by_params(versioned_resource_class('AllergyIntolerance'), patient: @instance.patient_id)
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply

      end

      test 'Server returns expected results from AllergyIntolerance search by patient' do
        metadata do
          id '02'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        
        patient_val = @instance.patient_id
        search_params = { 'patient': patient_val }

        reply = get_resource_by_params(versioned_resource_class('AllergyIntolerance'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)

        resource_count = reply.try(:resource).try(:entry).try(:length) || 0
        @resources_found = true if resource_count.positive?

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        @allergyintolerance = reply.try(:resource).try(:entry).try(:first).try(:resource)
        validate_search_reply(versioned_resource_class('AllergyIntolerance'), reply, search_params)
        save_resource_ids_in_bundle(versioned_resource_class('AllergyIntolerance'), reply)
      
      end

      test 'Server returns expected results from AllergyIntolerance search by patient+clinical-status' do
        metadata do
          id '03'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@allergyintolerance.nil?, 'Expected valid AllergyIntolerance resource to be present'
        
        patient_val = @instance.patient_id
        clinical_status_val = @allergyintolerance&.clinicalStatus&.coding&.first&.code
        search_params = { 'patient': patient_val, 'clinical-status': clinical_status_val }

        reply = get_resource_by_params(versioned_resource_class('AllergyIntolerance'), search_params)
        assert_response_ok(reply)
      end

      test 'AllergyIntolerance read resource supported' do
        metadata do
          id '04'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:AllergyIntolerance, [:read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_read_reply(@allergyintolerance, versioned_resource_class('AllergyIntolerance'))
  
      end

      test 'AllergyIntolerance vread resource supported' do
        metadata do
          id '05'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:AllergyIntolerance, [:vread])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_vread_reply(@allergyintolerance, versioned_resource_class('AllergyIntolerance'))
  
      end

      test 'AllergyIntolerance history resource supported' do
        metadata do
          id '06'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:AllergyIntolerance, [:history])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_history_reply(@allergyintolerance, versioned_resource_class('AllergyIntolerance'))
  
      end

      test 'AllergyIntolerance resources associated with Patient conform to Argonaut profiles' do
        metadata do
          id '07'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-allergyintolerance.json'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        test_resources_against_profile('AllergyIntolerance')
  
      end

      test 'All references can be resolved' do
        metadata do
          id '08'
          link 'https://www.hl7.org/fhir/DSTU2/references.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:AllergyIntolerance, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_reference_resolutions(@allergyintolerance)
      end
    end
  end
end