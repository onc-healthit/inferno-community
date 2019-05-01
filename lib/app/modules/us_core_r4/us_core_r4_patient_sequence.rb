module Inferno
  module Sequence
    class USCoreR4PatientSequence < SequenceBase
      title 'US Core R4 Patient Tests'

      description 'Verify that the Patient resources on the FHIR server follow the US Core R4 Implementation Guide'

      test_id_prefix 'R4P'

      requires :token, :patient_id

      #TODO: Should this change to capability_supports?  CapabilityStatement is Normative after all
      conformance_supports :Patient

      details %(

        Patient profile requirements from [US Core R4 Server Capability Statement](http://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-r4-server.html#patient).

        Search requirements (as of 1 May 19):

        | Conformance | Parameter         | Type           |
        |-------------|-------------------|----------------|
        | SHALL       | name              | string         |
        | SHALL       | identifier        | token          |
        | SHALL       | family + gender   | string + token |
        | SHALL       | given + gender    | string + token |
        | SHALL       | name + gender     | string + token |
        | SHALL       | name + birthdate  | string + date  |

        Note: Terminology validation currently disabled.

      )

      def validate_resource_item(resource, property, value)
        case property
        when "name"
          names = resource&.name
          assert !names.nil? && names.length > 0, "No names found in patient resource"
          assert names.any?{|name| name&.family&.include?(value)}, "Family name on resource did not match name search parameter (#{value})."
        when "identifier"
          identifier = resource&.identifier&.first

          if value.include?("|")
            # Using the | format
            id_system = value.split("|").first
            id_value = value.split("|")[1]

            assert identifier&.value == id_value, "Identifier value on resource (#{identifier&.value}) did not match search parameter (#{id_value})"
            assert identifier&.system == id_system, "Identifier system on resource (#{identifier&.system}) did not match search parameter (#{id_system})"

          else
            assert identifier&.value == value, "Identifier value on resource (#{identifier&.value}) did not match search parameter (#{value})"
          end

        when "family"
          names = resource.try(:name)
          assert !names.nil? && names.length > 0, "No names found in patient resource"
          assert names.any?{|name| name.family.include?(value)}, "No family names in resource matched family name search parameter (#{value})."
        when "given"
          names = resource.try(:name)
          assert !names.nil? && names.length > 0, "No names found in patient resource"
          assert names.any?{|name| name.given.include?(value)}, "Given name on resource did not match given name search parameter (#{value})."
        when "birthdate"
          birthdate = resource.try(:birthDate)
          assert !birthdate.nil? && birthdate == value, "Birthdate on resource did not match birthdate search parameter (#{value})."
        when "gender"
          gender = resource.try(:gender)
          assert !gender.nil? && gender == value, "Gender on resource did not match gender search parameter (#{value})."
        end
      end

      test 'Server supports fetching a patient using a read' do
        metadata do
          id '01'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-patient.html'
          desc %(
            Servers return a patient resource

            ` GET [base]/Patient/[id]`
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

      # PROFILE CHECKING #

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


      # SEARCHING

      test 'Server returns expected results from Patient search by name' do

        metadata {
          id '03'
          link 'http://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-patient.html'
          desc %(
            A server has exposed a FHIR Patient search endpoint supporting at a minimum the following search parameters: name.
          )
          versions :r4
        }

        assert !@patient.nil?, 'Expected valid Patient resource to be present'
        family = @patient&.name&.first&.family
        assert !family.nil?, "Patient family name not returned"
        search_params = {name: family}
        reply = get_resource_by_params(versioned_resource_class('Patient'), search_params)
        validate_search_reply(versioned_resource_class('Patient'), reply, search_params)

      end
      
      test 'Server returns expected results from Patient search by identifier' do

        metadata {
          id '04'
          link 'http://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-patient.html'
          desc %(
            A server has exposed a FHIR Patient search endpoint supporting at a minimum the following search parameters: identifier.
          )
          versions :r4
        }

        assert !@patient.nil?, 'Expected valid Patient resource to be present'
        identifier = @patient&.identifier&.first
        assert !identifier.nil?, "Patient identifier not returned"
        assert !identifier.value.nil?, "No value provided in Patient identifier"
        search_params = {identifier: identifier.value}
        reply = get_resource_by_params(versioned_resource_class('Patient'), search_params)
        validate_search_reply(versioned_resource_class('Patient'), reply, search_params)

        assert !identifier.system.nil?, "No system provided in Patient identifier"
        search_params = {identifier: "#{identifier.system}|#{identifier.value}"}
        reply = get_resource_by_params(versioned_resource_class('Patient'), search_params)
        validate_search_reply(versioned_resource_class('Patient'), reply, search_params)
        
        search_params = {_id: @patient.id}
        reply = get_resource_by_params(versioned_resource_class('Patient'), search_params)
        validate_search_reply(versioned_resource_class('Patient'), reply, search_params)

      end

      test 'Server returns expected results from Patient search by family + gender' do

        metadata {
          id '05'
          link 'http://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-patient.html'
          desc %(
          )
          versions :r4
        }

        assert !@patient.nil?, 'Expected valid Patient resource to be present'
        family = @patient&.name&.first&.family
        assert !family.nil?, "Patient family name not returned"
        given = @patient&.name&.first&.given&.first
        assert !given.nil?, "Patient given name not returned"
        gender = @patient&.gender
        assert !gender.nil?, "Patient gender not returned"
        search_params = {family: family, gender: gender}
        reply = get_resource_by_params(versioned_resource_class('Patient'), search_params)
        validate_search_reply(versioned_resource_class('Patient'), reply, search_params)
      end

      test 'Server returns expected results from Patient search by given + gender' do

        metadata {
          id '06'
          link 'http://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-patient.html'
          desc %(
          )
          versions :r4
        }

        assert !@patient.nil?, 'Expected valid Patient resource to be present'
        family = @patient&.name&.first&.family
        assert !family.nil?, "Patient family name not returned"
        given = @patient&.name&.first&.given&.first
        assert !given.nil?, "Patient given name not returned"
        gender = @patient&.gender
        assert !gender.nil?, "Patient gender not returned"
        search_params = {given: given, gender: gender}
        reply = get_resource_by_params(versioned_resource_class('Patient'), search_params)
        validate_search_reply(versioned_resource_class('Patient'), reply, search_params)
      end

      test 'Server returns expected results from Patient search by name + gender' do

        metadata {
          id '07'
          link 'http://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-patient.html'
          desc %(
          )
          versions :r4
        }

        assert !@patient.nil?, 'Expected valid Patient resource to be present'
        family = @patient&.name&.first&.family
        assert !family.nil?, "Patient family name not returned"
        given = @patient&.name&.first&.given&.first
        assert !given.nil?, "Patient given name not returned"
        gender = @patient&.gender
        assert !gender.nil?, "Patient gender not returned"
        search_params = {name: family, gender: gender}
        reply = get_resource_by_params(versioned_resource_class('Patient'), search_params)
        validate_search_reply(versioned_resource_class('Patient'), reply, search_params)
      end

      test 'Server returns expected results from Patient search by name + birthdate' do

        metadata {
          id '08'
          link 'http://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-patient.html'
          desc %(
            A server has exposed a FHIR Patient search endpoint supporting at a minimum the following search parameters when at least 2 (example name and gender) are present: name, gender, birthdate.
          )
          versions :r4
        }

        assert !@patient.nil?, 'Expected valid Patient resource to be present'
        family = @patient&.name&.first&.family
        assert !family.nil?, "Patient family name not returned"
        given = @patient&.name&.first&.given&.first
        assert !given.nil?, "Patient given name not returned"
        birthdate = @patient&.birthDate
        assert !birthdate.nil?, "Patient birthDate not returned"
        search_params = {name: family, birthdate: birthdate}
        reply = get_resource_by_params(versioned_resource_class('Patient'), search_params)
        validate_search_reply(versioned_resource_class('Patient'), reply, search_params)

      end

      test 'Server returns expected results from Patient history resource' do

        metadata {
          id '09'
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
          id '10'
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