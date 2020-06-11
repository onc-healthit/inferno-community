# frozen_string_literal: true

require_relative 'bulk_data_export_sequence'

module Inferno
  module Sequence
    class BulkDataGroupExportSequence < BulkDataExportSequence
      extends_sequence BulkDataExportSequence

      group 'Bulk Data Group Export'

      title 'Group Compartment Export Tests'

      description 'Verify that Group compartment export on the Bulk Data server follow the Bulk Data Access Implementation Guide'

      test_id_prefix 'BDGE'

      requires :group_id, :bulk_url, :bulk_access_token, :bulk_lines_to_validate

      def endpoint
        'Group'
      end

      def resource_id
        @instance.group_id
      end

      def export_kick_off(endpoint,
                          id = nil,
                          search_params: nil,
                          headers: { accept: 'application/fhir+json', prefer: 'respond-async' },
                          use_token: true)
        skip_unless id.present?, 'Bulk Data Group export is skipped becasue Group ID is empty'
        super(endpoint, id, search_params: search_params, headers: headers, use_token: use_token)
      end

      def assert_output_has_type_url(output = @output)
        skip_unless resource_id.present?, 'Bulk Data Group export is skipped becasue Group ID is empty'
        super(output)
      end
    end
  end
end
