# frozen_string_literal: true

require_relative 'bulk_data_export_sequence'

module Inferno
  module Sequence
    class BulkDataPatientExportSequence < BulkDataExportSequence
      extends_sequence BulkDataExportSequence

      group 'Bulk Data Patient Export'

      title 'Patient Compartment Export Tests'

      description 'Verify that patient compartment export on the Bulk Data server follow the Bulk Data Access Implementation Guide'

      test_id_prefix 'Patient'

      requires :token
      conformance_supports :Patient

      def endpoint
        'Patient'
      end

      # def initialize(instance, client, disable_tls_tests = false, sequence_result = nil, metadata_only = false)
      #   binding.pry
      #   super(instance, client, disable_tls_tests, sequence_result, metadata_only)
      #   klass = :Patient
      # end

      # def check_export_kick_off(search_params: nil)
      #   klass = :Patient
      #   binding.pry
      #   super
      # end
    end
  end
end
