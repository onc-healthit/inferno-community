# frozen_string_literal: true

module Inferno
  module Sequence
    class ArgonautCareTeamSequence < SequenceBase
      group 'Argonaut Profile Conformance'

      title 'Care Team'

      description 'Verify that CareTeam resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

      test_id_prefix 'ARCT'

      requires :token, :patient_id
      conformance_supports :CarePlan

      def validate_resource_item(resource, property, value)
        case property
        when 'patient'
          assert (resource.subject&.reference&.include?(value)), 'Subject on resource does not match patient requested'
        when 'category'
          categories = resource.try(:category)
          assert !categories.nil? && !categories.empty?, 'Category on resource did not match category requested'
          categories.each do |category|
            codings = category.try(:coding)
            assert !codings.nil?, 'Category on resource did not match category requested'
            assert codings.any? { |coding| !coding.try(:code).nil? && coding.try(:code) == value }, 'Category on resource did not match category requested'
          end
        end
      end

      details %(
        # Background

        The #{title} Sequence tests `#{title.gsub(/\s+/, '')}` resources associated with the provided patient.  The resources
        returned will be checked for consistency against the [#{title} Argonaut Profile](https://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-#{title.gsub(/\s+/, '').downcase}.html)

        # Test Methodology

        This test suite accesses the server endpoint at `/#{title.gsub(/\s+/, '')}/?category=careteam&patient={id}` using a `GET` request.
        It parses the #{title} and verifies that it contains:

        * A code representing the status of the #{title}
        * A reference to the patient to whom the #{title} belongs
        * A code representing the category of the #{title}
        * A participant role for each member of the #{title}
        * Names for certain #{title} members

        It collects the following information that is saved in the testing session for use by later tests:

        * List of `#{title.gsub(/\s+/, '')}` resources

        For more information on the #{title}, visit these links:

        * [FHIR DSTU2 Care Plan](https://www.hl7.org/fhir/DSTU2/careplan.html)
        * [Argonauts #{title} Profile](https://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-#{title.gsub(/\s+/, '').downcase}.html)
              )

      @resources_found = false

      test 'Server returns expected CareTeam results from CarePlan search by patient + category' do
        metadata do
          id '01'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            A server is capable of returning all of a patient's Assessment and Plan of Treatment information.
          )
          versions :dstu2
        end

        search_params = { patient: @instance.patient_id, category: 'careteam' }
        reply = get_resource_by_params(versioned_resource_class('CarePlan'), search_params)
        @careteam = reply.try(:resource).try(:entry).try(:first).try(:resource)
        validate_search_reply(versioned_resource_class('CarePlan'), reply, search_params)
        # save_resource_ids_in_bundle(versioned_resource_class('CarePlan'), reply)
      end

      test 'CareTeam resources associated with Patient conform to Argonaut profiles' do
        metadata do
          id '02'
          link 'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-careteam.html'
          desc %(
            CareTeam resources associated with Patient conform to Argonaut profiles.
          )
          versions :dstu2
        end
        test_resources_against_profile('CarePlan', Inferno::ValidationUtil::ARGONAUT_URIS[:care_team])
        skip_unless @profiles_encountered.include?(Inferno::ValidationUtil::ARGONAUT_URIS[:care_team]), 'No CareTeams found.'
        assert !@profiles_failed.include?(Inferno::ValidationUtil::ARGONAUT_URIS[:care_team]), "CareTeams failed validation.<br/>#{@profiles_failed[Inferno::ValidationUtil::ARGONAUT_URIS[:care_team]]}"
      end

      test 'All references can be resolved' do
        metadata do
          id '03'
          link 'https://www.hl7.org/fhir/DSTU2/references.html'
          desc %(
            All references in the CareTeam resource should be resolveable.
          )
          versions :dstu2
        end

        skip_if_not_supported(:CareTeam, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_reference_resolutions(@careteam)
      end
    end
  end
end
