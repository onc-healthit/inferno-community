# frozen_string_literal: true

module Inferno
  module Sequence
    class USCore310ProvenanceSequence < SequenceBase
      title 'Provenance Tests'

      description 'Verify that Provenance resources on the FHIR server follow the US Core Implementation Guide'

      test_id_prefix 'USCPROV'

      requires :token
      conformance_supports :Provenance
      delayed_sequence

      details %(
        The #{title} Sequence tests `#{title.gsub(/\s+/, '')}` resources associated with the provided patient.
      )

      @resources_found = false

      test :resource_read do
        metadata do
          id '01'
          name 'Can read Provenance from the server'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(
            Reference to Provenance can be resolved and read.
          )
          versions :r4
        end

        skip_if_not_supported(:Provenance, [:read])

        provenance_id = @instance.resource_references.find { |reference| reference.resource_type == 'Provenance' }&.resource_id
        skip 'No Provenance references found from the prior searches' if provenance_id.nil?

        @provenance = validate_read_reply(
          FHIR::Provenance.new(id: provenance_id),
          FHIR::Provenance
        )
        @provenance_ary = Array.wrap(@provenance).compact
        @resources_found = @provenance.present?
      end

      test :vread_interaction do
        metadata do
          id '02'
          name 'Provenance vread interaction supported'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(
            A server SHOULD support the Provenance vread interaction.
          )
          versions :r4
        end

        skip_if_not_supported(:Provenance, [:vread])
        skip 'No Provenance resources could be found for this patient. Please use patients with more information.' unless @resources_found

        validate_vread_reply(@provenance, versioned_resource_class('Provenance'))
      end

      test :history_interaction do
        metadata do
          id '03'
          name 'Provenance history interaction supported'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(
            A server SHOULD support the Provenance history interaction.
          )
          versions :r4
        end

        skip_if_not_supported(:Provenance, [:history])
        skip 'No Provenance resources could be found for this patient. Please use patients with more information.' unless @resources_found

        validate_history_reply(@provenance, versioned_resource_class('Provenance'))
      end

      test 'Provenance resources associated with Patient conform to US Core R4 profiles' do
        metadata do
          id '04'
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-provenance'
          description %(

            This test checks if the resources returned from prior searches conform to the US Core profiles.
            This includes checking for missing data elements and valueset verification.

          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        test_resources_against_profile('Provenance')
      end

      test 'At least one of every must support element is provided in any Provenance for this patient.' do
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

            Provenance.agent

            Provenance.agent.type

            Provenance.agent

            Provenance.agent.type

          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information' unless @provenance_ary&.any?
        must_support_confirmed = {}
        must_support_elements = [
          'Provenance.target',
          'Provenance.recorded',
          'Provenance.agent',
          'Provenance.agent.type',
          'Provenance.agent.who',
          'Provenance.agent.onBehalfOf',
          'Provenance.agent',
          'Provenance.agent.type',
          'Provenance.agent',
          'Provenance.agent.type'
        ]
        must_support_elements.each do |path|
          @provenance_ary&.each do |resource|
            truncated_path = path.gsub('Provenance.', '')
            must_support_confirmed[path] = true if can_resolve_path(resource, truncated_path)
            break if must_support_confirmed[path]
          end
          resource_count = @provenance_ary.length

          skip "Could not find #{path} in any of the #{resource_count} provided Provenance resource(s)" unless must_support_confirmed[path]
        end
        @instance.save!
      end

      test 'All references can be resolved' do
        metadata do
          id '06'
          link 'http://hl7.org/fhir/references.html'
          description %(
            This test checks if references found in resources from prior searches can be resolved.
          )
          versions :r4
        end

        skip_if_not_supported(:Provenance, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_reference_resolutions(@provenance)
      end
    end
  end
end
