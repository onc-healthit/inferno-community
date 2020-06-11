# frozen_string_literal: true

require_relative '../../../../test/test_helper'

describe Inferno::Sequence::BulkDataGroupExportSequence do
  before do
    @content_location = 'http://www.example.com/status'

    @sequence_class = Inferno::Sequence::BulkDataGroupExportSequence

    @instance = Inferno::Models::TestingInstance.create(
      url: 'http://www.example.com',
      bulk_url: 'https://www.example.com/bulk',
      bulk_access_token: 99_897_979
    )

    @instance.instance_variable_set(:'@module', OpenStruct.new(fhir_version: 'stu3'))

    @client = FHIR::Client.new(@instance.url)

    @export_request_headers = { accept: 'application/fhir+json',
                                prefer: 'respond-async',
                                authorization: "Bearer #{@instance.bulk_access_token}" }
  end

  describe 'skip when group ID is empty' do
    before do
      @sequence = @sequence_class.new(@instance, @client)
    end

    it 'skip export when group ID is empty' do
      error = assert_raises(Inferno::SkipException) do
        @sequence.export_kick_off(@sequence.endpoint, nil)
      end

      assert(error.message, 'Bulk Data Group export is skipped becasue Group ID is empty')
    end

    it 'skip assert output when group ID is empty' do
      error = assert_raises(Inferno::SkipException) do
        @sequence.assert_output_has_type_url
      end

      assert(error.message, 'Bulk Data Group export is skipped becasue Group ID is empty')
    end

    it 'test export when group ID is not empty' do
      export_url = @instance.bulk_url + '/Group/1/$export'
      response_headers = { content_location: @content_location }

      stub_request(:get, export_url)
        .with(headers: @export_request_headers)
        .to_return(
          status: 202,
          headers: response_headers
        )
      @sequence.export_kick_off(@sequence.endpoint, '1')
    end
  end
end
