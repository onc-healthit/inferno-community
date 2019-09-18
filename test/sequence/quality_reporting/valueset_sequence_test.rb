# frozen_string_literal: true

require File.expand_path '../../test_helper.rb', __dir__
# Tests for the ValueSetSequence
class ValueSetSequenceTest < MiniTest::Test
  REQUEST_HEADERS = {
    'Accept' => 'application/fhir+json',
    'Accept-Charset' => 'utf-8',
    'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
    'Format' => 'application/fhir+json',
    'Host' => 'www.example.com',
    'User-Agent' => 'Ruby FHIR Client'
  }.freeze

  MEASURES_TO_TEST = [
    {
      measure_id: 'MitreTestScript-measure-col'
    }
  ].freeze

  def setup
    @instance = Inferno::Models::TestingInstance.new(url: 'http://www.example.com', selected_module: 'quality_reporting')
    @instance.save!
    client = FHIR::Client.new(@instance.url)
    client.use_stu3
    client.default_json
    @sequence = Inferno::Sequence::ValueSetSequence.new(@instance, client, true)
  end

  def test_all_pass
    WebMock.reset!

    MEASURES_TO_TEST.each do
      # Mock a request for ValueSet?url=<url> to return 200
      stub_request(:get, /ValueSet/)
        .with(headers: REQUEST_HEADERS)
        .to_return(status: 200, body: '', headers: {})

      sequence_result = @sequence.start
      assert sequence_result.pass?, 'The sequence should be marked as pass.'
      assert sequence_result.test_results.all? { |r| r.pass? || r.skip? }, 'All tests should pass'
    end
  end

  def test_vs_not_found
    WebMock.reset!

    MEASURES_TO_TEST.each do
      # Mock a request for ValueSet?url=<url> to return 404
      stub_request(:get, /ValueSet/)
        .with(headers: REQUEST_HEADERS)
        .to_return(status: 404, body: '', headers: {})

      sequence_result = @sequence.start
      assert sequence_result.fail?, 'The sequence should be marked as fail.'
    end
  end
end
