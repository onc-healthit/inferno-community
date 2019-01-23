module Inferno
  module Sequence
    class ArgonautReadTwoPatientsSequence < SequenceBase

      title 'Read Two Separate Patients'

      description 'Verify that Patient resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

      test_id_prefix 'ARTP'

      requires :token, :extra_patient_id_1, :extra_patient_id_2
      conformance_supports :Patient

      test 'Patient IDs should not match' do

        metadata {
          id '01'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            
          )
          versions :dstu2
        }

        assert @instance.extra_patient_id_1 != @instance.extra_patient_id_2, "Must pass two separate patient IDs"

      end

      test 'Authorized to access first patient' do

        metadata {
          id '02'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            
          )
          versions :dstu2
        }

        patient_read_response = @client.read(versioned_resource_class('Patient'), @instance.extra_patient_id_1)
        assert_response_ok patient_read_response
        @patient = patient_read_response.resource
        assert !@patient.nil?, 'Expected valid Patient resource to be present'
        assert @patient.is_a?(versioned_resource_class('Patient')), 'Expected resource to be valid Patient'

      end

    
      test 'Authorized to access second patient' do

        metadata {
          id '03'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            
          )
          versions :dstu2
        }

        patient_read_response = @client.read(versioned_resource_class('Patient'), @instance.extra_patient_id_2)
        assert_response_ok patient_read_response
        @patient = patient_read_response.resource
        assert !@patient.nil?, 'Expected valid Patient resource to be present'
        assert @patient.is_a?(versioned_resource_class('Patient')), 'Expected resource to be valid Patient'

      end 

    end

  end
end
