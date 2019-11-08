# frozen_string_literal: true

module Inferno
  module Sequence
    class USCore310MedicationSequence < SequenceBase
      title 'Medication Tests'

      description 'Verify that Medication resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

      test_id_prefix 'USCM'

      requires :token
      conformance_supports :Medication
      delayed_sequence

      details %(

        The #{title} Sequence tests `#{title.gsub(/\s+/, '')}` resources associated with the provided patient.

      )

      @resources_found = false

      test 'Can read Medication from the server' do
        metadata do
          id '01'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          description %(
          )
          versions :r4
        end

        medication_id = @instance.resource_references.find { |reference| reference.resource_type == 'Medication' }&.resource_id
        skip 'No Medication references found from the prior searches' if medication_id.nil?
        @medication = fetch_resource('Medication', medication_id)
        @medication_ary = Array.wrap(@medication)
        @resources_found = !@medication.nil?
      end

      test 'Medication vread resource supported' do
        metadata do
          id '02'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          description %(
          )
          versions :r4
        end

        skip_if_not_supported(:Medication, [:vread])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_vread_reply(@medication, versioned_resource_class('Medication'))
      end

      test 'Medication history resource supported' do
        metadata do
          id '03'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          description %(
          )
          versions :r4
        end

        skip_if_not_supported(:Medication, [:history])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_history_reply(@medication, versioned_resource_class('Medication'))
      end

      test 'Server returns the appropriate resources from the following _revincludes: Provenance:target' do
        metadata do
          id '04'
          link 'https://www.hl7.org/fhir/search.html#revinclude'
          description %(
          )
          versions :r4
        end

        search_params = {}
        search_params['_revinclude'] = 'Provenance:target'
        reply = get_resource_by_params(versioned_resource_class('Medication'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)
        provenance_results = reply&.resource&.entry&.map(&:resource)&.any? { |resource| resource.resourceType == 'Provenance' }
        assert provenance_results, 'No Provenance resources were returned from this search'
      end

      test 'Medication resources associated with Patient conform to US Core R4 profiles' do
        metadata do
          id '05'
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-medication'
          description %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        test_resources_against_profile('Medication')
      end

      test 'At least one of every must support element is provided in any Medication for this patient.' do
        metadata do
          id '06'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/general-guidance.html/#must-support'
          description %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information' unless @medication_ary&.any?
        must_support_confirmed = {}
        must_support_elements = [
          'Medication.code'
        ]
        must_support_elements.each do |path|
          @medication_ary&.each do |resource|
            truncated_path = path.gsub('Medication.', '')
            must_support_confirmed[path] = true if can_resolve_path(resource, truncated_path)
            break if must_support_confirmed[path]
          end
          resource_count = @medication_ary.length

          skip "Could not find #{path} in any of the #{resource_count} provided Medication resource(s)" unless must_support_confirmed[path]
        end
        @instance.save!
      end

      test 'All references can be resolved' do
        metadata do
          id '07'
          link 'https://www.hl7.org/fhir/DSTU2/references.html'
          description %(
          )
          versions :r4
        end

        skip_if_not_supported(:Medication, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_reference_resolutions(@medication)
      end
    end
  end
end
