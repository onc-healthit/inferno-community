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

      test :validate_resources do
        metadata do
          id '02'
          name 'Provenance resources returned from previous search conform to the US Core Provenance Profile.'
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-provenance'
          description %(

            This test verifies resources returned from the first search conform to the [US Core Provenance Profile](http://hl7.org/fhir/us/core/StructureDefinition/us-core-provenance).
            It verifies the presence of manditory elements and that elements with required bindgings contain appropriate values.
            CodeableConcept element bindings will fail if none of its codings have a code/system that is part of the bound ValueSet.
            Quantity, Coding, and code element bindings will fail if its code/system is not found in the valueset.

          )
          versions :r4
        end

        skip_if_not_found(resource_type: 'Provenance', delayed: true)
        test_resources_against_profile('Provenance')
        bindings = USCore311ProvenanceSequenceDefinitions::BINDINGS
        invalid_binding_messages = []
        invalid_binding_resources = Set.new
        bindings.select { |binding_def| binding_def[:strength] == 'required' }.each do |binding_def|
          begin
            invalid_bindings = resources_with_invalid_binding(binding_def, @provenance_ary)
          rescue Inferno::Terminology::UnknownValueSetException => e
            warning do
              assert false, e.message
            end
            invalid_bindings = []
          end
          invalid_bindings.each { |invalid| invalid_binding_resources << "#{invalid[:resource]&.resourceType}/#{invalid[:resource].id}" }
          invalid_binding_messages.concat(invalid_bindings.map { |invalid| invalid_binding_message(invalid, binding_def) })
        end
        assert invalid_binding_messages.blank?, "#{invalid_binding_messages.count} invalid required #{'binding'.pluralize(invalid_binding_messages.count)}" \
        " found in #{invalid_binding_resources.count} #{'resource'.pluralize(invalid_binding_resources.count)}: " \
        "#{invalid_binding_messages.join('. ')}"

        bindings.select { |binding_def| binding_def[:strength] == 'extensible' }.each do |binding_def|
          begin
            invalid_bindings = resources_with_invalid_binding(binding_def, @provenance_ary)
            binding_def_new = binding_def
            # If the valueset binding wasn't valid, check if the codes are in the stated codesystem
            if invalid_bindings.present?
              invalid_bindings = resources_with_invalid_binding(binding_def.except(:system), @provenance_ary)
              binding_def_new = binding_def.except(:system)
            end
          rescue Inferno::Terminology::UnknownValueSetException, Inferno::Terminology::ValueSet::UnknownCodeSystemException => e
            warning do
              assert false, e.message
            end
            invalid_bindings = []
          end
          invalid_binding_messages.concat(invalid_bindings.map { |invalid| invalid_binding_message(invalid, binding_def_new) })
        end
        warning do
          invalid_binding_messages.each do |error_message|
            assert false, error_message
          end
        end
      end

      test 'All must support elements are provided in the Provenance resources returned.' do
        metadata do
          id '03'
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
              value_without_extensions.present? && (element[:fixed_value].blank? || value == element[:fixed_value])
            end

            value_found.present?
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
          id '04'
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
