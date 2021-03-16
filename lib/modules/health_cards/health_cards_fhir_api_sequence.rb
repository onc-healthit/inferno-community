# frozen_string_literal: true

require_relative './shared_health_cards_tests'

module Inferno
  module Sequence
    class HealthCardsFhirApiSequence < SequenceBase
      include SharedHealthCardsTests
      title 'Download and validate a health card via FHIR API'

      test_id_prefix 'HCFH'

      requires :url

      description 'Download and validate a health card via FHIR API (TODO)'

      details %(
      Download and validate a health card via FHIR API
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

        omit
      end

    end
  end
end
