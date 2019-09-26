# frozen_string_literal: true

module Inferno
  module Sequence
    class ConditionSequence < SequenceBase
      group 'US Core R4 Profile Conformance'

      title 'Condition (IPS) Tests'

      description 'Verify that Condition resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

      test_id_prefix 'Condition' # change me

      requires :token, :patient_id
      conformance_supports :Condition

      details %(

        The #{title} Sequence tests `#{title.gsub(/\s+/, '')}` resources associated with the provided patient.  The resources
        returned will be checked for consistency against the [Condition Argonaut Profile](http://hl7.org/fhir/uv/ips/StructureDefinition/Condition-uv-ips)

      )

      @resources_found = false

      test 'Condition resources associated with Patient conform to IPS profiles' do
        metadata do
          id '01'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Condition-uv-ips'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        test_resources_against_profile('Condition')
      end

      test 'At least one of every must support element is provided in any Condition for this patient.' do
        metadata do
          id '02'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/general-guidance.html/#must-support'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information' unless @condition_ary&.any?
        must_support_confirmed = {}
        must_support_elements = [
          'Condition',
          'Condition.id',
          'Condition.meta',
          'Condition.meta.profile',
          'Condition.clinicalStatus',
          'Condition.verificationStatus',
          'Condition.category',
          'Condition.severity',
          'Condition.code',
          'Condition.code',
          'Condition.bodySite',
          'Condition.subject',
          'Condition.subject.reference',
          'Condition.onsetDateTime',
          'Condition.abatementDateTime',
          'Condition.abatementAge',
          'Condition.abatementPeriod',
          'Condition.abatementRange',
          'Condition.abatementString',
          'Condition.asserter'
        ]
        must_support_elements.each do |path|
          @condition_ary&.each do |resource|
            truncated_path = path.gsub('Condition.', '')
            must_support_confirmed[path] = true if can_resolve_path(resource, truncated_path)
            break if must_support_confirmed[path]
          end
          resource_count = @condition_ary.length

          skip "Could not find #{path} in any of the #{resource_count} provided Condition resource(s)" unless must_support_confirmed[path]
        end
        @instance.save!
      end

      test 'All references can be resolved' do
        metadata do
          id '03'
          link 'https://www.hl7.org/fhir/DSTU2/references.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:Condition, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_reference_resolutions(@condition)
      end
    end
  end
end
