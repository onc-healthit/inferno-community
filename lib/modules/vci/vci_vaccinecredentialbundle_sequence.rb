# frozen_string_literal: true

module Inferno
  module Sequence
    class VciVaccinecredentialbundleSequence < SequenceBase
      include Inferno::SequenceUtilities

      title 'Vaccine Credential Bundle Tests'
      description 'Verify support for the server capabilities required by the Vaccine Credential Bundle profile.'
      details %(
      )
      test_id_prefix 'VCB'
      requires :vci_bundle

      @resource_found = nil

      def test_resources_against_profile(resource_type, resource, profile_url)
        #errors = resources.flat_map do |resource|
          validate_resource(resource_type, resource, profile_url)
        #end

        assert(errors.empty?, "\n* " + errors.join("\n* "))
      end

      test :resource_validate_profile do
        metadata do
          id '01'
          name 'Server returns Bundle resource that matches the Vaccine Credential Bundle profile'
          link 'http://hl7.org/fhir/us/smarthealthcards-vaccination/StructureDefinition/vaccine-credential-bundle'
          description %(
            This test will validate that the Bundle resource returned from the server matches the Vaccine Credential Bundle profile.
          )
          versions :r4
        end

        skip 'No resource returned/provided' unless @instance.vci_bundle.present?
        test_resources_against_profile('Bundle', @instance.vci_bundle, 'http://hl7.org/fhir/us/smarthealthcards-vaccination/StructureDefinition/vaccine-credential-bundle')
      end
    end
  end
end
