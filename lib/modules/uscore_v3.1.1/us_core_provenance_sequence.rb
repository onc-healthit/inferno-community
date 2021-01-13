# frozen_string_literal: true

require_relative './data_absent_reason_checker'
require_relative './profile_definitions/us_core_provenance_definitions'

module Inferno
  module Sequence
    class USCore311ProvenanceSequence < SequenceBase
      include Inferno::DataAbsentReasonChecker
      include Inferno::USCore311ProfileDefinitions

      title 'Provenance Tests'

      description 'Verify support for the server capabilities required by the US Core Provenance Profile.'

      details %(
        # Background

        The US Core #{title} sequence verifies that the system under test is able to provide correct responses
        for Provenance queries.  These queries must contain resources conforming to US Core Provenance Profile as specified
        in the US Core v3.1.1 Implementation Guide.

        # Testing Methodology


        Previously run sequences store references to US Core Provenance resources that are associated with other US Core
        resources using the appropriate `_revincludes` search.  This set of tests uses these found resources to verify
        support for the `read` operation.  Each of these resources must conform to the US Core Provenance profile.

        ## Must Support
        Each profile has a list of elements marked as "must support". This test sequence expects to see each of these elements
        at least once. If at least one cannot be found, the test will fail. The test will look through the Provenance
        resources found for these elements.

        ## Profile Validation
        Each resource returned from the first search is expected to conform to the [US Core Provenance Profile](http://hl7.org/fhir/us/core/StructureDefinition/us-core-provenance).
        Each element is checked against teminology binding and cardinality requirements.

        Elements with a required binding is validated against its bound valueset. If the code/system in the element is not part
        of the valueset, then the test will fail.

        ## Reference Validation
        Each reference within the resources found from the first search must resolve. The test will attempt to read each reference found
        and will fail if any attempted read fails.
      )

      test_id_prefix 'USCPROV'

      requires :token
      conformance_supports :Provenance
      delayed_sequence

      def patient_ids
        @instance.patient_ids.split(',').map(&:strip)
      end

      @resources_found = false

      test :resource_read do
        metadata do
          id '01'
          name 'Server returns correct Provenance resource from the Provenance read interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(
            This test will attempt to Reference to Provenance can be resolved and read.
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

      test 'All must support elements are provided in the Provenance resources returned.' do
        metadata do
          id '02'
          link 'http://www.hl7.org/fhir/us/core/general-guidance.html#must-support'
          description %(

            US Core Responders SHALL be capable of populating all data elements as part of the query results as specified by the US Core Server Capability Statement.
            This will look through the Provenance resources found previously for the following must support elements:

            * Provenance.agent:ProvenanceAuthor
            * Provenance.agent:ProvenanceTransmitter
            * agent
            * agent.onBehalfOf
            * agent.type
            * agent.type.coding.code
            * agent.type.coding.code
            * agent.who
            * recorded
            * target

          )
          versions :r4
        end

        skip_if_not_found(resource_type: 'Provenance', delayed: true)
        must_supports = USCore311ProvenanceSequenceDefinitions::MUST_SUPPORTS

        missing_slices = must_supports[:slices].reject do |slice|
          @provenance_ary&.any? do |resource|
            slice_found = find_slice(resource, slice[:path], slice[:discriminator])
            slice_found.present?
          end
        end

        missing_must_support_elements = must_supports[:elements].reject do |element|
          @provenance_ary&.any? do |resource|
            value_found = resolve_element_from_path(resource, element[:path]) do |value|
              value_without_extensions = value.respond_to?(:to_hash) ? value.to_hash.reject { |key, _| key == 'extension' } : value
              (value_without_extensions.present? || value_without_extensions == false) && (element[:fixed_value].blank? || value == element[:fixed_value])
            end

            # Note that false.present? => false, which is why we need to add this extra check
            value_found.present? || value_found == false
          end
        end
        missing_must_support_elements.map! { |must_support| "#{must_support[:path]}#{': ' + must_support[:fixed_value] if must_support[:fixed_value].present?}" }

        missing_must_support_elements += missing_slices.map { |slice| slice[:name] }

        skip_if missing_must_support_elements.present?,
                "Could not find #{missing_must_support_elements.join(', ')} in the #{@provenance_ary&.length} provided Provenance resource(s)"
        @instance.save!
      end

      test 'Every reference within Provenance resources can be read.' do
        metadata do
          id '03'
          link 'http://hl7.org/fhir/references.html'
          description %(

            This test will attempt to read the first 50 reference found in the resources from the first search.
            The test will fail if Inferno fails to read any of those references.

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
