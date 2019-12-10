# frozen_string_literal: true

require_relative 'bulk_data_export_sequence'

module Inferno
  module Sequence
    class BulkDataGroupExportSequence < BulkDataExportSequence
      extends_sequence BulkDataExportSequence

      group 'Bulk Data Group Export'

      title 'Group Compartment Export Tests'

      description 'Verify that Group compartment export on the Bulk Data server follow the Bulk Data Access Implementation Guide'

      test_id_prefix 'Group'

      requires :group_id, :bulk_access_token

      def endpoint
        'Group'
      end

      def resource_id
        @instance.group_id
      end
    end
  end
end
