# frozen_string_literal: true

require_relative '../health_cards/shared_health_cards_tests'
require_relative './shared_vci_bundle_tests'

module Inferno
  module Sequence
    class VciBundleSequence < SequenceBase
      include SharedVciBundleTests
      include Inferno::SequenceUtilities

      title 'Validates VCI FHIR Bundles'

      test_id_prefix 'VCIB'

      description 'VCI bundle validation '

      details %(
        Validates VCI Bundle
      )

      requires :vci_bundle_json

      def run_tests(inferno_tests)
        vci_bundle = FHIR::Bundle.new(JSON.parse(@instance.vci_bundle_json))
        @verifiable_credentials_bundles = [vci_bundle]

        super(inferno_tests)
      end

      resource_validate_bundle(index: '01')
      resource_validate_bundle_dm(index: '02')
    end
  end
end
