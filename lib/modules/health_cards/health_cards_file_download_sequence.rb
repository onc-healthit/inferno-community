# frozen_string_literal: true

require_relative './shared_health_cards_tests'

module Inferno
  module Sequence
    class HealthCardsFileDownloadSequence < SequenceBase
      include SharedHealthCardsTests

      title 'Download and validate a health card via File download'

      test_id_prefix 'HCF'

      requires :file_download_url, :extra_headers

      description 'Download and validate a health card via File download'

      details %(
        Download and validate a health card via File download
      )

      test :response_ok do
        metadata do
          id '01'
          name 'Server responds with 200OK'
          link 'https://smarthealth.cards/'
          description %(
            Placeholder
          )
        end

        
      end

      test :response_extension do
        metadata do
          id '02'
          name 'Response is served with the .smart-health-card extension'
          link 'https://smarthealth.cards/'
          description %(
            Placeholder
          )
        end
        
      end

      test :response_content_type do
        metadata do
          id '03'
          name 'Response contains correct Content-Type of application/smart-health-card'
          link 'https://smarthealth.cards/'
          description %(
            Placeholder
          )
        end
        
      end

      test :response_json do
        metadata do
          id '04'
          name 'Response body content is JSON object containing array of Verifiable Credential JWT strings'
          link 'https://smarthealth.cards/'
          description %(
            The guide says "should contain"?  What else could it contain?
          )
        end

        fixture_path = File.expand_path('./test/fixtures/', File.dirname(__FILE__))
        json_data = JSON.parse(File.read(File.join(fixture_path, 'example-00-e-file.smart-health-card')))
        @verifiable_credentials = json_data['verifiableCredential']
        
      end

      well_known(index: '10')
      valid_jws(index: '11')
    end
  end
end
