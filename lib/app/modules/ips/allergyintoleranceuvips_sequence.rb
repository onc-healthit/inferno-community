# frozen_string_literal: true

module Inferno
  module Sequence
    class AllergyIntoleranceSequence < SequenceBase
      group 'US Core R4 Profile Conformance'

      title 'Allergy Intolerance (IPS) Tests'

      description 'Verify that AllergyIntolerance resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

      test_id_prefix 'AllergyIntolerance' # change me

      requires :token, :patient_id
      conformance_supports :AllergyIntolerance

      details %(

        The #{title} Sequence tests `#{title.gsub(/\s+/, '')}` resources associated with the provided patient.  The resources
        returned will be checked for consistency against the [AllergyIntolerance Argonaut Profile](http://hl7.org/fhir/uv/ips/StructureDefinition/AllergyIntolerance-uv-ips)

      )

      @resources_found = false

      test 'AllergyIntolerance resources associated with Patient conform to IPS profiles' do
        metadata do
          id '01'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/AllergyIntolerance-uv-ips'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        test_resources_against_profile('AllergyIntolerance')
      end

      test 'At least one of every must support element is provided in any AllergyIntolerance for this patient.' do
        metadata do
          id '02'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/general-guidance.html/#must-support'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information' unless @allergyintolerance_ary&.any?
        must_support_confirmed = {}
        extensions_list = {
          'AllergyIntolerance.extension:abatement-datetime': 'http://hl7.org/fhir/uv/ips/StructureDefinition/abatement-dateTime-uv-ips'
        }
        extensions_list.each do |id, url|
          @allergyintolerance_ary&.each do |resource|
            must_support_confirmed[id] = true if resource.extension.any? { |extension| extension.url == url }
            break if must_support_confirmed[id]
          end
          skip "Could not find #{id} in any of the #{@allergyintolerance_ary.length} provided AllergyIntolerance resource(s)" unless must_support_confirmed[id]
        end

        must_support_elements = [
          'AllergyIntolerance',
          'AllergyIntolerance.id',
          'AllergyIntolerance.meta',
          'AllergyIntolerance.meta.profile',
          'AllergyIntolerance.clinicalStatus',
          'AllergyIntolerance.verificationStatus',
          'AllergyIntolerance.type',
          'AllergyIntolerance.criticality',
          'AllergyIntolerance.code',
          'AllergyIntolerance.code',
          'AllergyIntolerance.patient',
          'AllergyIntolerance.patient.reference',
          'AllergyIntolerance.onsetDateTime',
          'AllergyIntolerance.asserter',
          'AllergyIntolerance.reaction',
          'AllergyIntolerance.reaction.manifestation',
          'AllergyIntolerance.reaction.onset',
          'AllergyIntolerance.reaction.severity'
        ]
        must_support_elements.each do |path|
          @allergyintolerance_ary&.each do |resource|
            truncated_path = path.gsub('AllergyIntolerance.', '')
            must_support_confirmed[path] = true if can_resolve_path(resource, truncated_path)
            break if must_support_confirmed[path]
          end
          resource_count = @allergyintolerance_ary.length

          skip "Could not find #{path} in any of the #{resource_count} provided AllergyIntolerance resource(s)" unless must_support_confirmed[path]
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

        skip_if_not_supported(:AllergyIntolerance, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_reference_resolutions(@allergyintolerance)
      end
    end
  end
end
