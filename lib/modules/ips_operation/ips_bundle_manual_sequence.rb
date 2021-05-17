# frozen_string_literal: true

require_relative './ips_shared_bundle_tests'

module Inferno
  module Sequence
    class IpsBundleManualSequence < SequenceBase
      include Inferno::SequenceUtilities
      include SharedIpsBundleTests

      title 'Bundle Manual Tests'
      description 'Verify support for the server capabilities required by the Bundle (IPS) profile.'
      details %(
      )
      test_id_prefix 'BUIM'
      requires :ips_bundle_json

      def run_test(test)
        if (@bundle || []).empty?
          @bundle = FHIR::Bundle.new(JSON.parse(@instance.ips_bundle_json))
        end

        super(test)
      end

      resource_validate_bundle(index: '01')
      resource_validate_composition(index: '02')
      resource_validate_medication_statement(index: '03')
      resource_validate_allergy_intolerance(index: '04')
      resource_validate_condition(index: '05')
    end
  end
end
