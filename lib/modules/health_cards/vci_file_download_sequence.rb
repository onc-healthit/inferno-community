# frozen_string_literal: true

require_relative './shared_health_cards_tests'

module Inferno
  module Sequence
    class VciFileDownloadSequence < HealthCardsFileDownloadSequence # NOTE HOW THIS HAS DIFFERENT SUPERCLASS
      extends_sequence HealthCardsFileDownloadSequence #NOTE THIS LINE
      title 'Validates File Download against VCI profiles (FOR DEMO ONLY, REMOVE)'

      test_id_prefix 'VCIFD'

      description 'VCI file download validation '

      details %(
        Validates jws content
      )

      # PROVIDED
      # @jws_expanded

      test :vci_first do
        metadata do
          id '10'
          name 'VCI Validation Test'
          link 'https://smarthealth.cards/'
          description %(
            Placeholder
          )
        end

        @verifiable_credentials_bundles.each do |vc|
          # put in real validation code here
          # assert vc.valid?


        end

        skip 'Test not implemented'
      end
    end
  end
end
