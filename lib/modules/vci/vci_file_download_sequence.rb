# frozen_string_literal: true

require_relative '../health_cards/shared_health_cards_tests'
require_relative './shared_vci_bundle_tests'

module Inferno
  module Sequence
    class VciFileDownloadSequence < HealthCardsFileDownloadSequence
      extends_sequence HealthCardsFileDownloadSequence
      include SharedVciBundleTests

      title 'Validates File Download against VCI profiles'

      test_id_prefix 'VCIFD'

      requires :file_download_url

      description 'VCI file download validation '

      details %(
        Validates Vaccine Credentials from downloaded file
      )

      resource_validate_bundle(index: '01')
      resource_validate_bundle_dm(index: '02')
    end
  end
end
