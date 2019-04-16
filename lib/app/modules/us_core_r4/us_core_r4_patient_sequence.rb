module Inferno
  module Sequence
    class USCoreR4PatientSequence < SequenceBase
      title 'US Core R4 Patient'

      description 'Verify that the Patient resources on the FHIR server follow the US Core R4 Implementation Guide'

      test_id_prefix 'R4'

      requires :token, :patient_id

      #TODO: Should this change to capability_supports?  CapabilityStatement is Normative after all
      conformance_supports :Patient

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
    end
  end
end