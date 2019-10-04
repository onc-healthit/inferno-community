# frozen_string_literal: true

require_relative 'bulk_data_export_sequence'

module Inferno
  module Sequence
    class BulkDataPatientExportSequence < BulkDataExportSequence
      group 'Bulk Data Patient Export'

      title 'Patient Compartment Export Tests'

      description 'Verify that patient compartment export on the Bulk Data server follow the Bulk Data Access Implementation Guide'

      test_id_prefix 'Patient'

      requires :token
      conformance_supports :Patient

      @klass = :Patient
    end
  end
end
