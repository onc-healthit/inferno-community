module Inferno
  module Sequence
    class ArgonautPatientReadOnlySequence < SequenceBase

      title 'Patient'

      description 'Verify that Patient resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

      test_id_prefix 'ARPA'

      requires :token, :patient_id
      conformance_supports :Patient

      test 'Server rejects patient read without proper authorization' do

        metadata {
          id '01'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            A patient read does not work without authorization.
          )
          versions :dstu2
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
            All servers SHALL make available the read interactions for the Argonaut Profiles the server chooses to support.
          )
          versions :dstu2
        }

        patient_read_response = @client.read(versioned_resource_class('Patient'), @instance.patient_id)
        assert_response_ok patient_read_response
        @patient = patient_read_response.resource
        assert !@patient.nil?, 'Expected valid Patient resource to be present'
        assert @patient.is_a?(versioned_resource_class('Patient')), 'Expected resource to be valid Patient'

      end

      test 'Patient validates against Argonaut Profile' do

        metadata {
          id '03'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            A server returns valid FHIR Patient resources according to the [Data Access Framework (DAF) Patient Profile](http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-patient.html).
          )
          versions :dstu2
        }

        assert !@patient.nil?, 'Expected valid Patient resource to be present'
        assert @patient.is_a?(versioned_resource_class('Patient')), 'Expected resource to be valid Patient'
        profile = Inferno::ValidationUtil.guess_profile(@patient, @instance.fhir_version.to_sym)
        errors = profile.validate_resource(@patient)
        assert errors.empty?, "Patient did not validate against profile: #{errors.join(", ")}"
      end

      test 'Patient has address' do

        metadata {
          id '04'
          desc %(
            Additional Patient resource requirement
          )
          versions :dstu2
        }

        assert !@patient.nil?, 'Expected valid Patient resource to be present'
        assert @patient.is_a?(versioned_resource_class('Patient')), 'Expected resource to be valid Patient'
        address = @patient.try(:address).try(:first)
        assert !address.nil?, 'Patient address not returned'
      end

      test 'Patient has telecom' do

        metadata {
          id '05'
          desc %(
            Additional Patient resource requirement
          )
          versions :dstu2
        }

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


      test 'All references can be resolved' do

        metadata {
          id '06'
          link 'https://www.hl7.org/fhir/DSTU2/references.html'
          desc %(
            All references in the Patient resource should be resolveable.
          )
          versions :dstu2
        }

        assert !@patient.nil?, 'Expected valid Patient resource to be present'

        validate_reference_resolutions(@patient)

      end

    end

  end
end
