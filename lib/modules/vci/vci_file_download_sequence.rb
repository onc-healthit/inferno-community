# frozen_string_literal: true

require_relative './shared_health_cards_tests'

module Inferno
  module Sequence
    class VciFileDownloadSequence < HealthCardsFileDownloadSequence # NOTE HOW THIS HAS DIFFERENT SUPERCLASS
      extends_sequence HealthCardsFileDownloadSequence # NOTE THIS LINE
      title 'Validates File Download against VCI profiles (FOR DEMO ONLY, REMOVE)'

      test_id_prefix 'VCIFD'

      description 'VCI file download validation '

      details %(
        Validates jws content
      )

      test :vci_first do
        metadata do
          id '01'
          name 'Bundle resource returned matches the Vaccine Credential Bundle profile'
          link 'http://hl7.org/fhir/us/smarthealthcards-vaccination/StructureDefinition/vaccine-credential-bundle'
          description %(
            This test will validate that the Bundle resource returned from the server matches the Vaccine Credential Bundle profile.
          )
          versions :r4
        end

        skip 'No resource returned/provided' unless @verifiable_credentials_bundles.present?

        line_count = 0
        validation_error_collection = {}
        # @vci_bundle = FHIR::Bundle.new(JSON.parse(@instance.vci_bundle_json)) if @vci_bundle.nil?
        # errors = test_resource_against_profile('Bundle', @vci_bundle, 'http://hl7.org/fhir/us/smarthealthcards-vaccination/StructureDefinition/vaccine-credential-bundle')
        # assert(errors.empty?, "\n* " + errors.join("\n* "))

        @verifiable_credentials_bundles.each do |vc|
          # put in real validation code here
          # assert vc.valid?
        end

        skip 'Test not implemented'
      end
    end
  end
end
