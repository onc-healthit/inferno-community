# frozen_string_literal: true

module Inferno
  module Sequence
    class VciBundleSequence < SequenceBase
      include Inferno::SequenceUtilities

      title 'Vaccine Credential Bundle Tests'
      description 'Verify support for the server capabilities required by the Vaccine Credential Bundle profile.'
      details %(
      )
      test_id_prefix 'VCB'
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

        skip 'No resource returned/provided' unless @vci_bundle.present? || @instance.vci_bundle_json.present?

        @vci_bundle = FHIR::Bundle.new(JSON.parse(@instance.vci_bundle_json)) if @vci_bundle.nil?
        test_resources_against_profile('Bundle', @vci_bundle, 'http://hl7.org/fhir/us/smarthealthcards-vaccination/StructureDefinition/vaccine-credential-bundle')
      end
    end
  end
end
