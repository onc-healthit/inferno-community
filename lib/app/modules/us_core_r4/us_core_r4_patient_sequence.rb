module Inferno
  module Sequence
    class USCoreR4PatientSequence < SequenceBase
      title 'Patient'

      description 'Verify that the Patient resources on the FHIR server follow the US Core R4 Implementation Guide'

      test_id_prefix 'R4P'

      requires :token, :patient_id

      #TODO: Should this change to capability_supports?  CapabilityStatement is Normative after all
      conformance_supports :Patient

      def validate_resource_item(resource, property, value)
        case property
        when "identifier"
          identifier = resource.try(:identifier).try(:first).try(:value)
          assert !identifier.nil? && identifier == value, "Identifier on resource did not match identifier requested"
        when "family"
          names = resource.try(:name)
          assert !names.nil? && names.length > 0, "No names found in patient resource"
          assert names.any?{|name| name.family.include?(value)}, "Family name on resource did not match family name requested"
        when "given"
          names = resource.try(:name)
          assert !names.nil? && names.length > 0, "No names found in patient resource"
          assert names.any?{|name| name.given.include?(value)}, "Family name on resource did not match family name requested"
        when "birthdate"
          birthdate = resource.try(:birthDate)
          assert !birthdate.nil? && birthdate == value, "Birthdate on resource did not match birthdate requested"
        when "gender"
          gender = resource.try(:gender)
          assert !gender.nil? && gender == value, "Gender on resource did not match gender requested"
        end
      end

      test 'Server returns expected results from Patient read resource' do
        metadata do
          id '01'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-patient.html'
          desc %(
            Servers return a patient resource
               )
          versions :r4
        end

        @client.set_no_auth
        @client.set_bearer_token(@instance.token)
        reply = @client.read(versioned_resource_class('Patient'), @instance.patient_id)
        assert_response_ok reply
        @patient = reply.resource
        assert !@patient.nil?
        assert @patient.is_a?(versioned_resource_class('Patient')), 'Expected resource to be valid Patient'
        assert @patient.is_a?(FHIR::Patient), 'Not the right fhir model type'

      end

      test 'Patient validates against US Core R4 Profile' do
        metadata do
          id '02'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-patient.html'
          desc %(
            Validating the returned Patient against the US Core R4 Patient Profile
               )
          versions :r4
        end

        assert !@patient.nil?, 'Expected valid Patient resource to be present'
        assert @patient.is_a?(versioned_resource_class('Patient')), 'Expected resource to be valid Patient'
        assert (@instance.fhir_version.to_sym == :r4), 'Expected Version to be R4'
        profile = Inferno::ValidationUtil.guess_profile(@patient, @instance.fhir_version.to_sym)
        assert (profile.title == '**UPDATED** US Core Patient Profile **UPDATED**'), 'Expected correct profile'
        assert profile.is_a?(FHIR::StructureDefinition), 'Expecetd R4 Structure Defintion'
        errors = profile.validate_resource(@patient)
        assert errors.empty?, "Patient did not validate against profile: #{errors.join(", ")}"
      end


      test 'Server returns expected results from Patient search by identifier' do

        metadata {
          id '07'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            A server has exposed a FHIR Patient search endpoint supporting at a minimum the following search parameters: identifier.
          )
          versions :r4
        }

        assert !@patient.nil?, 'Expected valid Patient resource to be present'
        identifier = @patient.try(:identifier).try(:first).try(:value)
        assert !identifier.nil?, "Patient identifier not returned"
        search_params = {identifier: identifier}
        reply = get_resource_by_params(versioned_resource_class('Patient'), search_params)
        validate_search_reply(versioned_resource_class('Patient'), reply, search_params)

      end

      test 'Server returns expected results from Patient search by name + gender' do

        metadata {
          id '08'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            A server has exposed a FHIR Patient search endpoint supporting at a minimum the following search parameters when at least 2 (example name and gender) are present: name, gender, birthdate.
          )
          versions :r4
        }

        assert !@patient.nil?, 'Expected valid Patient resource to be present'
        family = @patient.try(:name).try(:first).try(:family).try(:first)
        assert !family.nil?, "Patient family name not returned"
        given = @patient.try(:name).try(:first).try(:given).try(:first)
        assert !given.nil?, "Patient given name not returned"
        gender = @patient.try(:gender)
        assert !gender.nil?, "Patient gender not returned"
        search_params = {family: family, given: given, gender: gender}
        reply = get_resource_by_params(versioned_resource_class('Patient'), search_params)
        validate_search_reply(versioned_resource_class('Patient'), reply, search_params)
      end

      test 'Server returns expected results from Patient search by name + birthdate' do

        metadata {
          id '09'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            A server has exposed a FHIR Patient search endpoint supporting at a minimum the following search parameters when at least 2 (example name and gender) are present: name, gender, birthdate.
          )
          versions :r4
        }

        assert !@patient.nil?, 'Expected valid Patient resource to be present'
        family = @patient.try(:name).try(:first).try(:family).try(:first)
        assert !family.nil?, "Patient family name not returned"
        given = @patient.try(:name).try(:first).try(:given).try(:first)
        assert !given.nil?, "Patient given name not returned"
        birthdate = @patient.try(:birthDate)
        assert !birthdate.nil?, "Patient birthDate not returned"
        search_params = {family: family, given: given, birthdate: birthdate}
        reply = get_resource_by_params(versioned_resource_class('Patient'), search_params)
        validate_search_reply(versioned_resource_class('Patient'), reply, search_params)

      end

      test 'Server returns expected results from Patient search by gender + birthdate' do

        metadata {
          id '10'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            A server has exposed a FHIR Patient search endpoint supporting at a minimum the following search parameters when at least 2 (example name and gender) are present: name, gender, birthdate.
          )
          versions :r4
        }

        assert !@patient.nil?, 'Expected valid Patient resource to be present'
        gender = @patient.try(:gender)
        assert !gender.nil?, "Patient gender not returned"
        birthdate = @patient.try(:birthDate)
        assert !birthdate.nil?, "Patient birthDate not returned"
        search_params = {gender: gender, birthdate: birthdate}
        reply = get_resource_by_params(versioned_resource_class('Patient'), search_params)
        validate_search_reply(versioned_resource_class('Patient'), reply, search_params)

      end

      test 'Server returns expected results from Patient history resource' do

        metadata {
          id '11'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          optional
          desc %(
            All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.          )
          versions :r4
        }

        validate_history_reply(@patient, versioned_resource_class('Patient'))

      end

      test 'Server returns expected results from Patient vread resource' do

        metadata {
          id '12'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          optional
          desc %(
            All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.
          )
          versions :r4
        }

        validate_vread_reply(@patient, versioned_resource_class('Patient'))

      end

      test 'All references can be resolved' do

        metadata {
          id '13'
          link 'https://www.hl7.org/fhir/DSTU2/references.html'
          desc %(
            All references in the Patient resource should be resolveable.
          )
          versions :r4
        }

        assert !@patient.nil?, 'Expected valid Patient resource to be present'

        validate_reference_resolutions(@patient)

      end
    end
  end
end