# frozen_string_literal: true

require_relative './data_absent_reason_checker'

module Inferno
  module Sequence
    class USCore310ProvenanceSequence < SequenceBase
      include Inferno::DataAbsentReasonChecker

      title 'Provenance Tests'

      description 'Verify that Provenance resources on the FHIR server follow the US Core Implementation Guide'

      test_id_prefix 'USCPROV'

      requires :token
      new_requires
      conformance_supports :Provenance
      delayed_sequence

      details %(
        The #{title} Sequence tests `#{title.gsub(/\s+/, '')}` resources associated with the provided patient.
      )

      def patient_ids
        @instance.get_requirement_value('patient_ids').split(',').map(&:strip)
      end

      @resources_found = false

      test :resource_read do
        metadata do
          id '01'
          name 'Server returns correct Provenance resource from the Provenance read interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(
            Reference to Provenance can be resolved and read.
          )
          versions :r4
        end

        skip_if_known_not_supported(:Provenance, [:read])

        provenance_references = @instance.resource_references.select { |reference| reference.resource_type == 'Provenance' }
        skip 'No Provenance references found from the prior searches' if provenance_references.blank?

        @provenance_ary = provenance_references.map do |reference|
          validate_read_reply(
            FHIR::Provenance.new(id: reference.resource_id),
            FHIR::Provenance,
            check_for_data_absent_reasons
          )
        end
        @provenance = @provenance_ary.first
        @resources_found = @provenance.present?
      end

      test :vread_interaction do
        metadata do
          id '02'
          name 'Server returns correct Provenance resource from Provenance vread interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(
            A server SHOULD support the Provenance vread interaction.
          )
          versions :r4
        end

        skip_if_known_not_supported(:Provenance, [:vread])
        skip_if_not_found(resource_type: 'Provenance', delayed: true)

        validate_vread_reply(@provenance, versioned_resource_class('Provenance'))
      end

      test :history_interaction do
        metadata do
          id '03'
          name 'Server returns correct Provenance resource from Provenance history interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(
            A server SHOULD support the Provenance history interaction.
          )
          versions :r4
        end

        skip_if_known_not_supported(:Provenance, [:history])
        skip_if_not_found(resource_type: 'Provenance', delayed: true)

        validate_history_reply(@provenance, versioned_resource_class('Provenance'))
      end

      test :validate_resources do
        metadata do
          id '04'
          name 'Provenance resources returned conform to US Core R4 profiles'
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-provenance'
          description %(

            This test checks if the resources returned from prior searches conform to the US Core profiles.
            This includes checking for missing data elements and valueset verification.

          )
          versions :r4
        end

        skip_if_not_found(resource_type: 'Provenance', delayed: true)
        test_resources_against_profile('Provenance')
      end

      test 'All must support elements are provided in the Provenance resources returned.' do
        metadata do
          id '05'
          link 'http://www.hl7.org/fhir/us/core/general-guidance.html#must-support'
          description %(

            US Core Responders SHALL be capable of populating all data elements as part of the query results as specified by the US Core Server Capability Statement.
            This will look through all Provenance resources returned from prior searches to see if any of them provide the following must support elements:

            Provenance.target

            Provenance.recorded

            Provenance.agent

            Provenance.agent.type

            Provenance.agent.who

            Provenance.agent.onBehalfOf

            Provenance.agent.type.coding.code

            Provenance.agent.type.coding.code

            Provenance.agent:ProvenanceAuthor

            Provenance.agent:ProvenanceTransmitter

          )
          versions :r4
        end

        skip_if_not_found(resource_type: 'Provenance', delayed: true)

        must_support_slices = [
          {
            name: 'Provenance.agent:ProvenanceAuthor',
            path: 'Provenance.agent',
            discriminator: {
              type: 'patternCodeableConcept',
              path: 'type',
              code: 'author',
              system: 'http://terminology.hl7.org/CodeSystem/provenance-participant-type'
            }
          },
          {
            name: 'Provenance.agent:ProvenanceTransmitter',
            path: 'Provenance.agent',
            discriminator: {
              type: 'patternCodeableConcept',
              path: 'type',
              code: 'transmitter',
              system: 'http://hl7.org/fhir/us/core/CodeSystem/us-core-provenance-participant-type'
            }
          }
        ]
        missing_slices = must_support_slices.reject do |slice|
          truncated_path = slice[:path].gsub('Provenance.', '')
          @provenance_ary&.any? do |resource|
            slice_found = find_slice(resource, truncated_path, slice[:discriminator])
            slice_found.present?
          end
        end

        must_support_elements = [
          { path: 'Provenance.target' },
          { path: 'Provenance.recorded' },
          { path: 'Provenance.agent' },
          { path: 'Provenance.agent.type' },
          { path: 'Provenance.agent.who' },
          { path: 'Provenance.agent.onBehalfOf' },
          { path: 'Provenance.agent.type.coding.code', fixed_value: 'author' },
          { path: 'Provenance.agent.type.coding.code', fixed_value: 'transmitter' }
        ]

        missing_must_support_elements = must_support_elements.reject do |element|
          truncated_path = element[:path].gsub('Provenance.', '')
          @provenance_ary&.any? do |resource|
            value_found = resolve_element_from_path(resource, truncated_path) { |value| element[:fixed_value].blank? || value == element[:fixed_value] }
            value_found.present?
          end
        end
        missing_must_support_elements.map! { |must_support| "#{must_support[:path]}#{': ' + must_support[:fixed_value] if must_support[:fixed_value].present?}" }

        missing_must_support_elements += missing_slices.map { |slice| slice[:name] }

        skip_if missing_must_support_elements.present?,
                "Could not find #{missing_must_support_elements.join(', ')} in the #{@provenance_ary&.length} provided Provenance resource(s)"
        @instance.save!
      end

      test 'Every reference within Provenance resource is valid and can be read.' do
        metadata do
          id '06'
          link 'http://hl7.org/fhir/references.html'
          description %(
            This test checks if references found in resources from prior searches can be resolved.
          )
          versions :r4
        end

        skip_if_known_not_supported(:Provenance, [:search, :read])
        skip_if_not_found(resource_type: 'Provenance', delayed: true)

        validated_resources = Set.new
        max_resolutions = 50

        @provenance_ary&.each do |resource|
          validate_reference_resolutions(resource, validated_resources, max_resolutions) if validated_resources.length < max_resolutions
        end
      end
    end
  end
end
