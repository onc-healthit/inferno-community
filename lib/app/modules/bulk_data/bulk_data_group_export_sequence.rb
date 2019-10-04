# frozen_string_literal: true

require_relative 'bulk_data_export_sequence'

module Inferno
  module Sequence
    class BulkDataGroupExportSequence < BulkDataExportSequence
      group 'Bulk Data Group Export'

      title 'Group Compartment Export Tests'

      description 'Verify that Group compartment export on the Bulk Data server follow the Bulk Data Access Implementation Guide'

      test_id_prefix 'Group'

      requires :token, :group_id

      @klass = :Group
    end
  end
end
