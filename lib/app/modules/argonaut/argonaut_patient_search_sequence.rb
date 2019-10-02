# frozen_string_literal: true

module Inferno
  module Sequence
    class ArgonautPatientSequence < SequenceBase
      title 'Patient'

      description 'Verify that Patient resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

      test_id_prefix 'ARPS'

      requires :token, :patient_id
      conformance_supports :Patient

      def validate_resource_item(resource, property, value)
        case property
        when 'identifier'
          identifier = resource.try(:identifier).try(:first).try(:value)
          assert !identifier.nil? && identifier == value, 'Identifier on resource did not match identifier requested'
        when 'family'
          names = resource.try(:name)
          assert !names.nil? && !names.empty?, 'No names found in patient resource'
          assert names.any? { |name| name.family.include?(value) }, 'Family name on resource did not match family name requested'
        when 'given'
          names = resource.try(:name)
          assert !names.nil? && !names.empty?, 'No names found in patient resource'
          assert names.any? { |name| name.given.include?(value) }, 'Family name on resource did not match family name requested'
        when 'birthdate'
          birthdate = resource.try(:birthDate)
          assert !birthdate.nil? && birthdate == value, 'Birthdate on resource did not match birthdate requested'
        when 'gender'
          gender = resource.try(:gender)
          assert !gender.nil? && gender == value, 'Gender on resource did not match gender requested'
        end
      end

      test 'Server rejects patient read without proper authorization' do
        metadata do
          id '01'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            A patient read does not work without authorization.
          )
          versions :dstu2
        end

        @client.set_no_auth
        skip 'Could not verify this functionality when bearer token is not set' if @instance.token.blank?

        reply = @client.read(versioned_resource_class('Patient'), @instance.patient_id)
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply
      end

      test 'Server returns expected results from Patient read resource' do
        metadata do
          id '02'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            All servers SHALL make available the read interactions for the Argonaut Profiles the server chooses to support.
          )
          versions :dstu2
        end

        patient_read_response = @client.read(versioned_resource_class('Patient'), @instance.patient_id)
        assert_response_ok patient_read_response
        @patient = patient_read_response.resource
        assert !@patient.nil?, 'Expected valid Patient resource to be present'
        assert @patient.is_a?(versioned_resource_class('Patient')), 'Expected resource to be valid Patient'
      end

      test 'Patient validates against Argonaut Profile' do
        metadata do
          id '03'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            A server returns valid FHIR Patient resources according to the [Data Access Framework (DAF) Patient Profile](http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-patient.html).
          )
          versions :dstu2
        end

        assert !@patient.nil?, 'Expected valid Patient resource to be present'
        assert @patient.is_a?(versioned_resource_class('Patient')), 'Expected resource to be valid Patient'
        profile = Inferno::ValidationUtil.guess_profile(@patient, @instance.fhir_version.to_sym)
        errors = profile.validate_resource(@patient)
        assert errors.empty?, "Patient did not validate against profile: #{errors.join(', ')}"
      end

      test 'Patient has address' do
        metadata do
          id '04'
          desc %(
            Additional Patient resource requirement
          )
          versions :dstu2
        end

        assert !@patient.nil?, 'Expected valid Patient resource to be present'
        assert @patient.is_a?(versioned_resource_class('Patient')), 'Expected resource to be valid Patient'
        address = @patient.try(:address).try(:first)
        assert !address.nil?, 'Patient address not returned'
      end

      test 'Patient has telecom' do
        metadata do
          id '05'
          desc %(
            Additional Patient resource requirement
          )
          versions :dstu2
        end

        assert !@patient.nil?, 'Expected valid Patient resource to be present'
        assert @patient.is_a?(versioned_resource_class('Patient')), 'Expected resource to be valid Patient'
        telecom = @patient.try(:telecom).try(:first)
        assert !telecom.nil?, 'Patient telecom not returned'
      end

      # test 'Patient supports $everything operation' do

      #   metadata {
      #     id '00'
      #     optional
      #     desc %(
      #       Additional Patient resource requirement
      #     )
      #   }
      # test 'Patient supports $everything operation', '', 'DISCUSSION REQUIRED', :optional do
      #   everything_response = @client.fetch_patient_record(@instance.patient_id)
      #   skip_unless [200, 201].include?(everything_response.code)
      #   @everything = everything_response.resource
      #   assert !@everything.nil?, 'Expected valid Bundle resource on $everything request'
      #   assert @everything.is_a?(versioned_resource_class('Bundle')), 'Expected resource to be valid Bundle'
      # end

      test 'Server rejects Patient search without proper authorization' do
        metadata do
          id '06'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            A Patient search does not work without proper authorization.          )
          versions :dstu2
        end

        skip 'Could not verify this functionality when bearer token is not set' if @instance.token.blank?

        assert !@patient.nil?, 'Expected valid Patient resource to be present'
        identifier = @patient.try(:identifier).try(:first).try(:value)
        assert !identifier.nil?, 'Patient identifier not returned'
        @client.set_no_auth
        reply = get_resource_by_params(versioned_resource_class('Patient'), identifier: identifier)
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply
      end

      test 'Server returns expected results from Patient search by identifier' do
        metadata do
          id '07'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            A server has exposed a FHIR Patient search endpoint supporting at a minimum the following search parameters: identifier.
          )
          versions :dstu2
        end

        assert !@patient.nil?, 'Expected valid Patient resource to be present'
        identifier = @patient.try(:identifier).try(:first).try(:value)
        assert !identifier.nil?, 'Patient identifier not returned'
        search_params = { identifier: identifier }
        reply = get_resource_by_params(versioned_resource_class('Patient'), search_params)
        validate_search_reply(versioned_resource_class('Patient'), reply, search_params)
      end

      test 'Server returns expected results from Patient search by name + gender' do
        metadata do
          id '08'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            A server has exposed a FHIR Patient search endpoint supporting at a minimum the following search parameters when at least 2 (example name and gender) are present: name, gender, birthdate.
          )
          versions :dstu2
        end

        assert !@patient.nil?, 'Expected valid Patient resource to be present'
        family = @patient.try(:name).try(:first).try(:family).try(:first)
        assert !family.nil?, 'Patient family name not returned'
        given = @patient.try(:name).try(:first).try(:given).try(:first)
        assert !given.nil?, 'Patient given name not returned'
        gender = @patient.try(:gender)
        assert !gender.nil?, 'Patient gender not returned'
        search_params = { family: family, given: given, gender: gender }
        reply = get_resource_by_params(versioned_resource_class('Patient'), search_params)
        validate_search_reply(versioned_resource_class('Patient'), reply, search_params)
      end

      test 'Server returns expected results from Patient search by name + birthdate' do
        metadata do
          id '09'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            A server has exposed a FHIR Patient search endpoint supporting at a minimum the following search parameters when at least 2 (example name and gender) are present: name, gender, birthdate.
          )
          versions :dstu2
        end

        assert !@patient.nil?, 'Expected valid Patient resource to be present'
        family = @patient.try(:name).try(:first).try(:family).try(:first)
        assert !family.nil?, 'Patient family name not returned'
        given = @patient.try(:name).try(:first).try(:given).try(:first)
        assert !given.nil?, 'Patient given name not returned'
        birthdate = @patient.try(:birthDate)
        assert !birthdate.nil?, 'Patient birthDate not returned'
        search_params = { family: family, given: given, birthdate: birthdate }
        reply = get_resource_by_params(versioned_resource_class('Patient'), search_params)
        validate_search_reply(versioned_resource_class('Patient'), reply, search_params)
      end

      test 'Server returns expected results from Patient search by gender + birthdate' do
        metadata do
          id '10'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            A server has exposed a FHIR Patient search endpoint supporting at a minimum the following search parameters when at least 2 (example name and gender) are present: name, gender, birthdate.
          )
          versions :dstu2
        end

        assert !@patient.nil?, 'Expected valid Patient resource to be present'
        gender = @patient.try(:gender)
        assert !gender.nil?, 'Patient gender not returned'
        birthdate = @patient.try(:birthDate)
        assert !birthdate.nil?, 'Patient birthDate not returned'
        search_params = { gender: gender, birthdate: birthdate }
        reply = get_resource_by_params(versioned_resource_class('Patient'), search_params)
        validate_search_reply(versioned_resource_class('Patient'), reply, search_params)
      end

      test 'Server returns expected results from Patient history resource' do
        metadata do
          id '11'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          optional
          desc %(
            All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.          )
          versions :dstu2
        end

        validate_history_reply(@patient, versioned_resource_class('Patient'))
      end

      test 'Server returns expected results from Patient vread resource' do
        metadata do
          id '12'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          optional
          desc %(
            All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.
          )
          versions :dstu2
        end

        validate_vread_reply(@patient, versioned_resource_class('Patient'))
      end

      test 'All references can be resolved' do
        metadata do
          id '13'
          link 'https://www.hl7.org/fhir/DSTU2/references.html'
          desc %(
            All references in the Patient resource should be resolveable.
          )
          versions :dstu2
        end

        assert !@patient.nil?, 'Expected valid Patient resource to be present'

        validate_reference_resolutions(@patient)
      end
    end
  end
end
