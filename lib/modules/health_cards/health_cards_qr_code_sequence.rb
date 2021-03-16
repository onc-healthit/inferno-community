# frozen_string_literal: true

require_relative './shared_health_cards_tests'

module Inferno
  module Sequence
    class HealthCardsQrCodeSequence < SequenceBase
      title 'Download and validate a health card via QR Code (TODO)'

      test_id_prefix 'HCQR'

      requires :qr_code

      description 'Download and validate a health card via QR Code'

      details %(
        Download and validate a health card via QR Code
      )

      test :placeholder_test do
        metadata do
          id '01'
          name 'Placeholder'
          link 'https://smarthealth.cards/'
          description %(
            Placeholder
          )
        end
      end
    end
  end
end
