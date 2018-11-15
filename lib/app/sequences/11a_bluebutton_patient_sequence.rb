module Inferno
  module Sequence
    class BlueButtonPatientSequence < SequenceBase

      title 'Patient'

      description 'Verify that Patient resources on the FHIR server follow the BlueButton 2.0 Implementation Guide'

      test_id_prefix 'BBPA'

      requires :token, :patient_id

      test 'Server rejects patient read without proper authorization' do

        metadata {
          id '01'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            A patient read does not work without authorization.
          )
          versions :stu3
        }

        @client.set_no_auth
        skip 'Could not verify this functionality when bearer token is not set' if @instance.token.blank?

        reply = @client.read(versioned_resource_class('Patient'), @instance.patient_id)
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply

      end

      test 'Server returns expected results from Patient read resource' do

        metadata {
          id '02'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            All servers SHALL make available the read interactions for the BlueButton Profiles the server chooses to support.
          )
          versions :stu3
        }

        patient_read_response = @client.read(versioned_resource_class('Patient'), @instance.patient_id)
        assert_response_ok patient_read_response
        @patient = patient_read_response.resource
        assert !@patient.nil?, 'Expected valid Patient resource to be present'
        assert @patient.is_a?(versioned_resource_class('Patient')), 'Expected resource to be valid Patient'

      end

      test 'Patient validates against BlueButton Profile' do

        metadata {
          id '03'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            A server returns valid FHIR Patient resources according to the [Data Access Framework (DAF) Patient Profile](http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-patient.html).
          )
          versions :stu3
        }

        assert !@patient.nil?, 'Expected valid Patient resource to be present'
        assert @patient.is_a?(versioned_resource_class('Patient')), 'Expected resource to be valid Patient'
        profile = Inferno::ValidationUtil.guess_profile(@patient, @instance.version.to_sym)
        errors = profile.validate_resource(@patient)
        assert errors.empty?, "Patient did not validate against profile: #{errors.join(", ")}"
      end

      test 'All references can be resolved' do

        metadata {
          id '04'
          link ''
          desc %(
            All references in the Patient resource should be resolveable.
          )
          versions :stu3
        }

        assert !@patient.nil?, 'Expected valid Patient resource to be present'
        assert @patient.is_a?(versioned_resource_class('Patient')), 'Expected resource to be valid Patient'

        validate_reference_resolutions(@patient)

      end

    end
  end
end
