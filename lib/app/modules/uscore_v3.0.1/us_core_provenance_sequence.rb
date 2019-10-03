# frozen_string_literal: true

module Inferno
  module Sequence
    class USCore301ProvenanceSequence < SequenceBase
      title 'Provenance Tests'

      description 'Verify that Provenance resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

      test_id_prefix 'USCPROV'

      requires :token
      conformance_supports :Provenance
      delayed_sequence

      details %(

        The #{title} Sequence tests `#{title.gsub(/\s+/, '')}` resources associated with the provided patient.

      )

      @resources_found = false

      test 'Can read Provenance from the server' do
        metadata do
          id '01'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        provenance_id = @instance.resource_references.find { |reference| reference.resource_type == 'Provenance' }&.resource_id
        skip 'No Provenance references found from the prior searches' if provenance_id.nil?
        @provenance = fetch_resource('Provenance', provenance_id)
        @resources_found = !@provenance.nil?
      end

      test 'Provenance vread resource supported' do
        metadata do
          id '02'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:Provenance, [:vread])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_vread_reply(@provenance, versioned_resource_class('Provenance'))
      end

      test 'Provenance history resource supported' do
        metadata do
          id '03'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:Provenance, [:history])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_history_reply(@provenance, versioned_resource_class('Provenance'))
      end

      test 'Provenance resources associated with Patient conform to US Core R4 profiles' do
        metadata do
          id '04'
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-provenance'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        test_resources_against_profile('Provenance')
      end

      test 'At least one of every must support element is provided in any Provenance for this patient.' do
        metadata do
          id '05'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/general-guidance.html/#must-support'
          desc %(
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
          link 'https://www.hl7.org/fhir/DSTU2/references.html'
          desc %(
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
