# frozen_string_literal: true

module Inferno
  module Sequence
    class ArgonautCarePlanSequence < SequenceBase
      PROFILE = Inferno::ValidationUtil::ARGONAUT_URIS[:care_plan]

      group 'Argonaut Profile Conformance'

      title 'Care Plan'

      description 'Verify that CarePlan resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

      test_id_prefix 'ARCP'

      requires :token, :patient_id
      conformance_supports :CarePlan

      def validate_resource_item(resource, property, value)
        case property
        when 'patient'
          assert resource.subject&.reference&.include?(value), 'Subject on resource does not match patient requested'
        when 'category'
          categories = resource.try(:category)
          assert !categories.nil? && !categories.empty?, 'Category on resource did not match category requested'
          categories.each do |category|
            codings = category.try(:coding)
            assert !codings.nil?, 'Category on resource did not match category requested'
            assert codings.any? { |coding| !coding.try(:code).nil? && coding.try(:code) == value }, 'Category on resource did not match category requested'
          end
        when 'date'
          # todo
        when 'status'
          status = resource.try(:status)
          assert !status.nil? && status == value, 'Status on resource did not match status requested'
        end
      end

      details %(
        # Background

        The #{title} Sequence tests `#{title.gsub(/\s+/, '')}` resources associated with the provided patient.  The resources
        returned will be checked for consistency against the [#{title} Argonaut Profile](https://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-careplan.html)

        # Test Methodology

        This test suite accesses the server endpoint at `/#{title.gsub(/\s+/, '')}/?category=assess-plan&patient={id}` using a `GET` request.
        It parses the #{title} and verifies that it contains:

        * A narrative of the patient assessment and treatment plan
        * A code representing the status of the care plan
        * A reference to the patient to whom the #{title} belongs
        * A code representing the category of the "assess plan"

        It collects the following information that is saved in the testing session for use by later tests:

        * List of `#{title.gsub(/\s+/, '')}` resources

        For more information on the #{title}, visit these links:

        * [FHIR DSTU2 #{title}](https://www.hl7.org/fhir/DSTU2/#{title.gsub(/\s+/, '')}.html)
        * [Argonauts #{title} Profile](https://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-#{title.gsub(/\s+/, '').downcase}.html)
              )

      @resources_found = false

      test 'Server rejects CarePlan search without authorization' do
        metadata do
          id '01'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          description %(
            A CarePlan search does not work without proper authorization.
          )
          versions :dstu2
        end

        @client.set_no_auth
        skip 'Could not verify this functionality when bearer token is not set' if @instance.token.blank?

        reply = get_resource_by_params(versioned_resource_class('CarePlan'), patient: @instance.patient_id, category: 'assess-plan')
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply
      end

      test 'Server returns expected results from CarePlan search by patient + category' do
        metadata do
          id '02'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          description %(
            A server is capable of returning all of a patient's Assessment and Plan of Treatment information.
          )
          versions :dstu2
        end

        search_params = { patient: @instance.patient_id, category: 'assess-plan' }
        reply = get_resource_by_params(versioned_resource_class('CarePlan'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)

        resource_count = reply.try(:resource).try(:entry).try(:length) || 0
        @resources_found = true if resource_count.positive?

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        @careplan = reply.try(:resource).try(:entry).try(:first).try(:resource)
        validate_search_reply(versioned_resource_class('CarePlan'), reply, search_params)
        save_resource_ids_in_bundle(versioned_resource_class('CarePlan'), reply, PROFILE)
      end

      test 'Server returns expected results from CarePlan search by patient + category + date' do
        metadata do
          id '03'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          optional
          description %(
            A server SHOULD be capable of returning a patient's Assessment and Plan of Treatment information over a specified time period.
          )
          versions :dstu2
        end

        skip_if_not_supported(:CarePlan, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        assert !@careplan.nil?, 'Expected valid CarePlan resource to be present'

        date = @careplan.try(:period).try(:start)
        assert !date.nil?, 'CarePlan period not returned'
        search_params = { patient: @instance.patient_id, category: 'assess-plan', date: date }
        reply = get_resource_by_params(versioned_resource_class('CarePlan'), search_params)
        validate_search_reply(versioned_resource_class('CarePlan'), reply, search_params)
      end

      test 'Server returns expected results from CarePlan search by patient + category + status' do
        metadata do
          id '04'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          optional
          description %(
            A server SHOULD be capable returning all of a patient's active Assessment and Plan of Treatment information.
          )
          versions :dstu2
        end

        skip_if_not_supported(:CarePlan, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        search_params = { patient: @instance.patient_id, category: 'assess-plan', status: 'active' }
        reply = get_resource_by_params(versioned_resource_class('CarePlan'), search_params)
        validate_search_reply(versioned_resource_class('CarePlan'), reply, search_params)
      end

      test 'Server returns expected results from CarePlan search by patient + category + status + date' do
        metadata do
          id '05'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          optional
          description %(
            A server SHOULD be capable returning a patient's active Assessment and Plan of Treatment information over a specified time period.
          )
          versions :dstu2
        end

        skip_if_not_supported(:CarePlan, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        assert !@careplan.nil?, 'Expected valid CarePlan resource to be present'
        date = @careplan.try(:period).try(:start)
        assert !date.nil?, 'CarePlan period not returned'
        search_params = { patient: @instance.patient_id, category: 'assess-plan', status: 'active', date: date }
        reply = get_resource_by_params(versioned_resource_class('CarePlan'), search_params)
        validate_search_reply(versioned_resource_class('CarePlan'), reply, search_params)
      end

      test 'Server returns expected results from CarePlan read resource' do
        metadata do
          id '06'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          description %(
            All servers SHALL make available the read interactions for the Argonaut Profiles the server chooses to support.
          )
          versions :dstu2
        end

        skip_if_not_supported(:CarePlan, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_read_reply(@careplan, versioned_resource_class('CarePlan'))
      end

      test 'Careplan history resource supported' do
        metadata do
          id '07'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          optional
          description %(
            All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.
          )
          versions :dstu2
        end

        skip_if_not_supported(:CarePlan, [:history])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_history_reply(@careplan, versioned_resource_class('CarePlan'))
      end

      test 'CarePlan vread resource supported' do
        metadata do
          id '08'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          optional
          description %(
            All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.
          )
          versions :dstu2
        end

        skip_if_not_supported(:CarePlan, [:vread])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_vread_reply(@careplan, versioned_resource_class('CarePlan'))
      end

      test 'CarePlan resources associated with Patient conform to Argonaut profiles' do
        metadata do
          id '09'
          link 'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-careplan.html'
          description %(
            CarePlan resources associated with Patient conform to Argonaut profiles.
          )
          versions :dstu2
        end
        test_resources_against_profile('CarePlan', PROFILE)
        skip_unless @profiles_encountered.include?(PROFILE), 'No CarePlans found.'
        assert !@profiles_failed.include?(PROFILE), "CarePlans failed validation.<br/>#{@profiles_failed[PROFILE]}"
      end

      test 'All references can be resolved' do
        metadata do
          id '10'
          link 'https://www.hl7.org/fhir/DSTU2/references.html'
          description %(
            All references in the CarePlan resource should be resolveable.
          )
          versions :dstu2
        end

        skip_if_not_supported(:CarePlan, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_reference_resolutions(@careplan)
      end
    end
  end
end
