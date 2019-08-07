# frozen_string_literal: true

module Inferno
  module Sequence
    class USCoreR4MedicationSequence < SequenceBase
      group 'US Core R4 Profile Conformance'

      title 'Medication Tests'

      description 'Verify that Medication resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

      test_id_prefix 'Medication' # change me

      requires :token, :medication
      conformance_supports :Medication

      details %(

        The #{title} Sequence tests `#{title.gsub(/\s+/, '')}` resources associated with the provided patient.  The resources
        returned will be checked for consistency against the [Medication Argonaut Profile](https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-medication)

      )

      @resources_found = false

      test 'Can read Medication from the server' do
        metadata do
          id '01'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        @medication = fetch_resource('Medication', @instance.medication)
        validate_read_reply(@medication, versioned_resource_class('Medication'))
        @resources_found = !@medication.nil?
      end

      test 'Medication vread resource supported' do
        metadata do
          id '02'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
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
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:Medication, [:history])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_history_reply(@medication, versioned_resource_class('Medication'))
      end

      test 'Medication resources associated with Patient conform to US Core R4 profiles' do
        metadata do
          id '04'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-medication.json'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        test_resources_against_profile('Medication')
      end

      test 'At least one of every must support element is provided in any Medication for this patient.' do
        metadata do
          id '05'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/general-guidance.html/#must-support'
          desc %(
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
          id '06'
          link 'https://www.hl7.org/fhir/DSTU2/references.html'
          desc %(
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
