# frozen_string_literal: true

module Inferno
  module Sequence
    class VciVaccinecredentiallaboratorybundleSequence < SequenceBase
      include Inferno::SequenceUtilities

      title 'Vaccine Credential Laboratory Bundle Tests'
      description 'Verify support for the server capabilities required by the Vaccine Credential Laboratory Bundle profile.'
      details %(
      )
      test_id_prefix 'VCLB'
      requires :bundle_id

      @resource_found = nil

      test :resource_read do
        metadata do
          id '01'
          name 'Server returns correct Bundle resource from the Bundle read interaction'
          link 'http://hl7.org/fhir/us/smarthealthcards-vaccination/StructureDefinition/vaccine-credential-laboratory-bundle'
          description %(
            This test will verify that Bundle resources can be read from the server.
          )
          versions :r4
        end

        resource_id = @instance.bundle_id
        @resource_found = validate_read_reply(FHIR::Bundle.new(id: resource_id), FHIR::Bundle)
        save_resource_references(versioned_resource_class('Bundle'), [@resource_found], 'http://hl7.org/fhir/us/smarthealthcards-vaccination/StructureDefinition/vaccine-credential-laboratory-bundle')
      end

      test :resource_validate_profile do
        metadata do
          id '02'
          name 'Server returns Bundle resource that matches the Vaccine Credential Laboratory Bundle profile'
          link 'http://hl7.org/fhir/us/smarthealthcards-vaccination/StructureDefinition/vaccine-credential-laboratory-bundle'
          description %(
            This test will validate that the Bundle resource returned from the server matches the Vaccine Credential Laboratory Bundle profile.
          )
          versions :r4
        end

        skip 'No resource found from Read test' unless @resource_found.present?
        test_resources_against_profile('Bundle', 'http://hl7.org/fhir/us/smarthealthcards-vaccination/StructureDefinition/vaccine-credential-laboratory-bundle')
      end
    end
  end
end
