# frozen_string_literal: true

module Inferno
  module Sequence
    class IpsCompositionuvipsSequence < SequenceBase
      include Inferno::SequenceUtilities

      title 'Composition (IPS) Tests'
      description 'Verify support for the server capabilities required by the Composition (IPS) profile.'
      details %(
      )
      test_id_prefix 'CUI'
      requires :composition_id

      @resource_found = nil

      test :resource_read do
        metadata do
          id '01'
          name 'Server returns correct Composition resource from the Composition read interaction'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Composition-uv-ips'
          description %(
            This test will verify that Composition resources can be read from the server.
          )
          versions :r4
        end

        resource_id = @instance.composition_id
        @resource_found = validate_read_reply(FHIR::Composition.new(id: resource_id), FHIR::Composition)
        save_resource_references(versioned_resource_class('Composition'), [@resource_found], 'http://hl7.org/fhir/uv/ips/StructureDefinition/Composition-uv-ips')
      end

      test :resource_validate_profile do
        metadata do
          id '02'
          name 'Server returns Composition resource that matches the Composition (IPS) profile'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Composition-uv-ips'
          description %(
            This test will validate that the Composition resource returned from the server matches the Composition (IPS) profile.
          )
          versions :r4
        end

        skip 'No resource found from Read test' unless @resource_found.present?
        test_resources_against_profile('Composition', 'http://hl7.org/fhir/uv/ips/StructureDefinition/Composition-uv-ips')
      end

      test :must_support do
        metadata do
          id '03'
          name 'All must support elements are provided in the Composition resources returned.'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Composition-uv-ips'
          optional
          description %(

            This will look through the Composition resource for the following must support elements:

            * Composition
            * Composition.event:careProvisioningEvent
            * Composition.section:sectionAdvanceDirectives.entry:advanceDirectivesConsent
            * Composition.section:sectionAllergies
            * Composition.section:sectionAllergies.entry:allergyOrIntolerance
            * Composition.section:sectionFunctionalStatus.entry:disability
            * Composition.section:sectionFunctionalStatus.entry:functionalAssessment
            * Composition.section:sectionImmunizations
            * Composition.section:sectionImmunizations.entry:immunization
            * Composition.section:sectionMedicalDevices
            * Composition.section:sectionMedicalDevices.entry:deviceStatement
            * Composition.section:sectionMedications
            * Composition.section:sectionMedications.entry:medicationStatement
            * Composition.section:sectionPastIllnessHx.entry:pastProblem
            * Composition.section:sectionPregnancyHx.entry:pregnancyOutcomeSummary
            * Composition.section:sectionPregnancyHx.entry:pregnancyStatus
            * Composition.section:sectionProblems
            * Composition.section:sectionProblems.entry:problem
            * Composition.section:sectionProceduresHx
            * Composition.section:sectionProceduresHx.entry:procedure
            * Composition.section:sectionResults
            * Composition.section:sectionResults.entry:results-diagnosticReport
            * Composition.section:sectionResults.entry:results-observation
            * Composition.section:sectionSocialHistory.entry:alcoholUse
            * Composition.section:sectionSocialHistory.entry:smokingTobaccoUse
            * Composition.section:sectionVitalSigns.entry:vitalSign
            * attester
            * attester.mode
            * attester.party
            * attester.time
            * author
            * date
            * event
            * event.code.coding.code
            * event.period
            * section
            * section.code
            * section.entry
            * section.text
            * section.title
            * status
            * subject
            * subject.reference
            * text
            * title
            * type.coding.code

          )
          versions :r4
        end

        skip 'No resource found from Read test' unless @resource_found.present?
        must_supports = IpsCompositionuvipsSequenceDefinitions::MUST_SUPPORTS

        missing_slices = must_supports[:slices]
          .select { |slice| slice[:discriminator].present? }
          .reject do |slice|
            slice_found = find_slice(@resource_found, slice[:path], slice[:discriminator])
            slice_found.present?
          end

        missing_must_support_elements = must_supports[:elements].reject do |element|
          value_found = resolve_element_from_path(@resource_found, element[:path]) do |value|
            value_without_extensions = value.respond_to?(:to_hash) ? value.to_hash.reject { |key, _| key == 'extension' } : value
            (value_without_extensions.present? || value_without_extensions == false) && (element[:fixed_value].blank? || value == element[:fixed_value])
          end

          # Note that false.present? => false, which is why we need to add this extra check
          value_found.present? || value_found == false
        end
        missing_must_support_elements.map! { |must_support| "#{must_support[:path]}#{': ' + must_support[:fixed_value] if must_support[:fixed_value].present?}" }

        missing_must_support_elements += missing_slices.map { |slice| slice[:name] }

        skip_if missing_must_support_elements.present?,
                "Could not find #{missing_must_support_elements.join(', ')} in the provided resource"
        @instance.save!
      end
    end
  end
end
