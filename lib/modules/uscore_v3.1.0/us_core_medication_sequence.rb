# frozen_string_literal: true

module Inferno
  module Sequence
    class USCore310MedicationSequence < SequenceBase
      title 'Medication Tests'

      description 'Verify that Medication resources on the FHIR server follow the US Core Implementation Guide'

      test_id_prefix 'USCM'

      requires :token
      conformance_supports :Medication
      delayed_sequence

      details %(
        The #{title} Sequence tests `#{title.gsub(/\s+/, '')}` resources associated with the provided patient.
      )

      @resources_found = false

      test :resource_read do
        metadata do
          id '01'
          name 'Server returns correct Medication resource from the Medication read interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(
            Reference to Medication can be resolved and read.
          )
          versions :r4
        end

        skip_if_not_supported(:Medication, [:read])

        medication_references = @instance.resource_references.select { |reference| reference.resource_type == 'Medication' }
        skip 'No Medication references found from the prior searches' if medication_references.blank?

        @medication_ary = medication_references.map do |reference|
          validate_read_reply(
            FHIR::Medication.new(id: reference.resource_id),
            FHIR::Medication
          )
        end
        @medication = @medication_ary.first
        @resources_found = @medication.present?
      end

      test 'Medication resources returned conform to US Core R4 profiles' do
        metadata do
          id '02'
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-medication'
          description %(

            This test checks if the resources returned from prior searches conform to the US Core profiles.
            This includes checking for missing data elements and valueset verification.

          )
          versions :r4
        end

        skip 'No Medication resources appear to be available.' unless @resources_found
        test_resources_against_profile('Medication')
      end

      test 'All must support elements are provided in the Medication resources returned.' do
        metadata do
          id '03'
          link 'http://www.hl7.org/fhir/us/core/general-guidance.html#must-support'
          description %(

            US Core Responders SHALL be capable of populating all data elements as part of the query results as specified by the US Core Server Capability Statement.
            This will look through all Medication resources returned from prior searches to see if any of them provide the following must support elements:

            Medication.code

          )
          versions :r4
        end

        skip 'No Medication resources appear to be available.' unless @resources_found
        must_support_confirmed = {}

        must_support_elements = [
          'Medication.code'
        ]
        must_support_elements.each do |path|
          @medication_ary&.each do |resource|
            truncated_path = path.gsub('Medication.', '')
            must_support_confirmed[path] = true if resolve_element_from_path(resource, truncated_path).present?
            break if must_support_confirmed[path]
          end
          resource_count = @medication_ary.length

          skip "Could not find #{path} in any of the #{resource_count} provided Medication resource(s)" unless must_support_confirmed[path]
        end
        @instance.save!
      end

      test 'Every reference within Medication resource is valid and can be read.' do
        metadata do
          id '04'
          link 'http://hl7.org/fhir/references.html'
          description %(
            This test checks if references found in resources from prior searches can be resolved.
          )
          versions :r4
        end

        skip_if_not_supported(:Medication, [:search, :read])
        skip 'No Medication resources appear to be available.' unless @resources_found

        validate_reference_resolutions(@medication)
      end
    end
  end
end
