# frozen_string_literal: true

require_relative './shared_health_cards_tests'

module Inferno
  module Sequence
    class VciFileDownloadSequence < HealthCardsFileDownloadSequence
      extends_sequence HealthCardsFileDownloadSequence
      title 'Validates File Download against VCI profiles (TODO)'

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

        # do something with jws_expanded

        omit
      end
    end
  end
end
