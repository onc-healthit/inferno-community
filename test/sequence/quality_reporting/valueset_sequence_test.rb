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

  CQF_REQUEST_HEADERS = {
    'Accept' => '*/*',
    'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
    'Host' => 'localhost:8080'
  }.freeze

  # load up the CMS130 'measure-col' bundle to use for testing
  PROJECT_ROOT = "#{__dir__}/../../.."
  MEASURE_COL_BUNDLE_PATH = File.expand_path('resources/quality_reporting/CMS130/Bundle/cms130-bundle.json', PROJECT_ROOT)
  MEASURE_COL_BUNDLE = FHIR::STU3::Bundle.new JSON.parse(File.read(MEASURE_COL_BUNDLE_PATH))

  MEASURES_TO_TEST = [
    {
      measure_id: 'MitreTestScript-measure-col',
      bundle: MEASURE_COL_BUNDLE
    }
  ].freeze

  def stub_measure_resource_requests(measure_info)
    measure_resource = measure_info[:bundle].entry.select { |e| e.resource.id == 'MitreTestScript-measure-col' }.first.resource
    stub_request(:get, "http://localhost:8080/cqf-ruler-dstu3/fhir/Measure/#{measure_info[:measure_id]}")
      .with(headers: CQF_REQUEST_HEADERS)
      .to_return(status: 200, body: measure_resource.to_json, headers: {})

    library_resources = measure_info[:bundle].entry.select { |e| e.resource.resourceType == 'Library' }.map(&:resource)
    library_resources.each do |library|
      stub_request(:get, "http://localhost:8080/cqf-ruler-dstu3/fhir/Library/#{library.id}")
        .with(headers: CQF_REQUEST_HEADERS)
        .to_return(status: 200, body: library.to_json, headers: {})
    end
  end

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

    MEASURES_TO_TEST.each do |measure_info|
      stub_request(:get, %r{http\:\/\/www\.example\.com\/ValueSet\/([0-9]+\.)+[0-9]+})
        .with(headers: REQUEST_HEADERS)
        .to_return(status: 200, body: '', headers: {})

      stub_measure_resource_requests(measure_info)

      @instance.measure_to_test = measure_info[:measure_id]
      sequence_result = @sequence.start
      assert sequence_result.pass?, 'The sequence should be marked as pass.'
      assert sequence_result.test_results.all? { |r| r.pass? || r.skip? }, 'All tests should pass'
    end
  end

  def test_vs_not_found
    WebMock.reset!

    MEASURES_TO_TEST.each do |measure_info|
      stub_request(:get, %r{http\:\/\/www\.example\.com\/ValueSet\/([0-9]+\.)+[0-9]+})
        .with(headers: REQUEST_HEADERS)
        .to_return(status: 404, body: '', headers: {})

      stub_measure_resource_requests(measure_info)

      @instance.measure_to_test = measure_info[:measure_id]
      sequence_result = @sequence.start
      assert sequence_result.fail?, 'The sequence should be marked as fail.'
    end
  end
end
