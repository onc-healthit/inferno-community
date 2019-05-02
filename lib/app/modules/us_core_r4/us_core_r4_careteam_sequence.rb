module Inferno
  module Sequence
    class USCoreR4CareTeamSequence < SequenceBase

      group 'US Core R4 Profile Conformance'

      title 'US Core R4 Care Team'

      description 'Verify that CareTeam resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

      test_id_prefix 'R4CT'

      requires :token, :patient_id
      conformance_supports :CareTeam

      def validate_resource_item (resource, property, value)
        case property
        when "patient"
          assert (resource.subject && resource.subject.reference.include?(value)), "Subject on resource does not match patient requested"
        when "category"
          categories = resource.try(:category)
          assert !categories.nil? && categories.length > 0, "Category on resource did not match category requested"
          categories.each do |category|
            codings = category.try(:coding)
            assert !codings.nil?, "Category on resource did not match category requested"
            assert codings.any? {|coding| !coding.try(:code).nil? && coding.try(:code) == value}, "Category on resource did not match category requested"
          end
        end
      end

      details %(


        | Conformance | Parameter        | Type              |
        |-------------|------------------|-------------------|
        | SHALL       | patient + status | reference + token |

            )

      @resources_found = false

      test 'Server returns expected CareTeam results from CareTeam search by patient + status' do

        metadata {
          id '01'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            A server is capable of returning all of a patient's Assessment and Plan of Treatment information.
          )
          versions :r4
        }

        search_params = {patient: @instance.patient_id, status: "active"}
        reply = get_resource_by_params(versioned_resource_class('CareTeam'), search_params)
        @careteam = reply.try(:resource).try(:entry).try(:first).try(:resource)
        validate_search_reply(versioned_resource_class('CareTeam'), reply, search_params)
        # save_resource_ids_in_bundle(versioned_resource_class('CarePlan'), reply)

      end

      test 'CareTeam resources associated with Patient conform to Argonaut profiles' do

        metadata {
          id '02'
          link 'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-careteam.html'
          desc %(
            CareTeam resources associated with Patient conform to Argonaut profiles.
          )
          versions :r4
        }
        test_resources_against_profile('CareTeam')
      end

      test 'All references can be resolved' do

        metadata {
          id '03'
          link 'https://www.hl7.org/fhir/DSTU2/references.html'
          desc %(
            All references in the CareTeam resource should be resolveable.
          )
          versions :dstu2
        }

        skip_if_not_supported(:CareTeam, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_reference_resolutions(@careteam)

      end

    end

  end
end
