# frozen_string_literal: true

module Inferno
  module Sequence
    class VciBundleSequence < SequenceBase
      include Inferno::SequenceUtilities

      title 'Vaccine Credential Bundle Tests'
      description 'Verify support for the server capabilities required by the Vaccine Credential Bundle profile.'
      details %(
      )
      test_id_prefix 'VCI'
      requires :vci_bundle_json

      attr_accessor :vci_bundle

      @resource_found = nil

      def test_resources_against_profile(resource_type, resource, profile_url)
        # Has to initialize profiles_failed otherwise validate_resource() failed.
        @profiles_failed ||= Hash.new { |hash, key| hash[key] = [] }

        p = Inferno::ValidationUtil::DEFINITIONS[profile_url]

        if p
          errors = validate_resource(resource_type, resource, p)
        else
          warn { assert false, 'No profiles found for this Resource' }
          issues = Inferno::RESOURCE_VALIDATOR.validate(resource, versioned_resource_class)
          errors = issues[:errors]
        end

        errors
      end

      test :resource_validate_bundle do
        metadata do
          id '01'
          name 'Bundle resource returned matches the Vaccine Credential Bundle profile'
          link 'http://hl7.org/fhir/us/smarthealthcards-vaccination/StructureDefinition/vaccine-credential-bundle'
          description %(
            This test will validate that the Bundle resource returned from the server matches the Vaccine Credential Bundle profile.
          )
          versions :r4
        end

        skip 'No resource returned/provided' unless @vci_bundle.present? || @instance.vci_bundle_json.present?

        @vci_bundle = FHIR::Bundle.new(JSON.parse(@instance.vci_bundle_json)) if @vci_bundle.nil?
        test_resources_against_profile('Bundle', @vci_bundle, 'http://hl7.org/fhir/us/smarthealthcards-vaccination/StructureDefinition/vaccine-credential-bundle')
      end

      test :resource_validate_patient_dm do
        metadata do
          id '02'
          name 'Patient resource in returned Bundle matches the Vaccine Credential Patient Data Minimization profiles'
          link 'http://build.fhir.org/ig/dvci/vaccine-credential-ig/branches/main/StructureDefinition-vaccine-credential-patient-dm'
          description %(
            This test will validate that the Patient resource in returned Bundle from the server matches the Vaccine Credential Patient Data Minimization profiles.
          )
          versions :r4
          optional
        end

        skip 'No resource returned/provided' unless @vci_bundle.present?

        errors = test_resources_against_profile('Patient', @vci_bundle.entry[0].resource, 'http://hl7.org/fhir/us/smarthealthcards-vaccination/StructureDefinition/vaccine-credential-patient-dm')
        assert(errors.empty?, "\n* " + errors.join("\n* "))
      end

      test :resource_validate_immunization_dm do
        metadata do
          id '03'
          name 'Immunization resources in returned Bundle matches the Vaccine Credential Immunization Data Minimization profiles'
          link 'http://build.fhir.org/ig/dvci/vaccine-credential-ig/branches/main/StructureDefinition-vaccine-credential-immunization-dm'
          description %(
            This test will validate that the Patient resource in returned Bundle from the server matches the Vaccine Credential Immunization Data Minimizationprofile.
          )
          versions :r4
          optional
        end

        skip 'No resource returned/provided' unless @vci_bundle.present?

        errors = []
        @vci_bundle.entry.each do |entry|
          next unless entry.resource.class == FHIR::Immunization

          errors << test_resources_against_profile('Immunization', entry.resource, 'http://hl7.org/fhir/us/smarthealthcards-vaccination/StructureDefinition/vaccine-credential-immunization-dm')
        end
        assert(errors.empty?, "\n* " + errors.join("\n* "))
      end
    end
  end
end
