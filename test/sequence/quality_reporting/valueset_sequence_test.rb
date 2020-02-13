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
    'Host' => 'localhost:8080',
    'User-Agent' => 'rest-client/2.1.0 (darwin18.7.0 x86_64) ruby/2.5.6p201'
  }.freeze

  # load up the CMS130 artifacts to use for testing
  PROJECT_ROOT = "#{__dir__}/../../.."
  EXM_130_MEASURE_PATH = File.expand_path('test/fixtures/measure-EXM130_FHIR4-7.2.000.json', PROJECT_ROOT)
  EXM_130_DEPENDENT_LIBRARY_BUNDLE_PATH = File.expand_path('test/fixtures/library-deps-EXM130_FHIR4-7.2.000-bundle.json', PROJECT_ROOT)
  EXM_130_MAIN_LIBRARY_PATH = File.expand_path('test/fixtures/library-EXM130_FHIR4-7.2.000.json', PROJECT_ROOT)
  EXM_130_MEASURE = FHIR::Measure.new JSON.parse(File.read(EXM_130_MEASURE_PATH))
  EXM_130_MAIN_LIBRARY = FHIR::Library.new JSON.parse(File.read(EXM_130_MAIN_LIBRARY_PATH))
  EXM_130_DEPENDENT_LIBRARY_BUNDLE = FHIR::Bundle.new JSON.parse(File.read(EXM_130_DEPENDENT_LIBRARY_BUNDLE_PATH))

  MEASURES_TO_TEST = [
    {
      measure: EXM_130_MEASURE,
      main_library: EXM_130_MAIN_LIBRARY,
      dependent_library_bundle: EXM_130_DEPENDENT_LIBRARY_BUNDLE
    }
  ].freeze

  def stub_measure_resource_requests(measure_info)
    measure_resource = measure_info[:measure]

    stub_request(:get, "http://localhost:8080/cqf-ruler-r4/fhir/Measure/#{measure_info[:measure].id}")
      .with(headers: CQF_REQUEST_HEADERS)
      .to_return(status: 200, body: measure_resource.to_json, headers: {})

    stub_request(:get, "http://localhost:8080/cqf-ruler-r4/fhir/Library/#{measure_info[:main_library].id}")
      .with(headers: CQF_REQUEST_HEADERS)
      .to_return(status: 200, body: measure_info[:main_library].to_json, headers: {})

    library_resources = measure_info[:dependent_library_bundle]
    library_resources.each do |library|
      stub_request(:get, "http://localhost:8080/cqf-ruler-r4/fhir/Library/#{library.id}")
        .with(headers: CQF_REQUEST_HEADERS)
        .to_return(status: 200, body: library.to_json, headers: {})
    end
  end

  def setup
    @instance = Inferno::Models::TestingInstance.new(url: 'http://www.example.com', selected_module: 'quality_reporting')
    @instance.save!
    client = FHIR::Client.new(@instance.url)
    client.use_r4
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

      @instance.measure_to_test = measure_info[:measure].id
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

      @instance.measure_to_test = measure_info[:measure].id
      sequence_result = @sequence.start
      assert sequence_result.fail?, 'The sequence should be marked as fail.'
    end
  end

  def test_measure_to_test_not_defined
    WebMock.reset!

    @instance.measure_to_test = nil
    sequence_result = @sequence.start
    assert sequence_result.fail?, 'The sequence should be marked as fail.'
  end
end
