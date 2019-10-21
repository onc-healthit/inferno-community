# frozen_string_literal: true

require File.expand_path '../test_helper.rb', __dir__
require_relative '../../lib/app/utils/bulk_data/ndjson_service_factory'

class NDJsonServiceTest < MiniTest::Test
  BUNDLES = [
    '../fixtures/Brett333_Gutmann970_2a29169c-f0b7-415b-aaf9-43ba107006ad.json',
    '../fixtures/Bud153_Renner328_0f3ae208-5a0f-4bb4-ba0d-267725ef964b.json'
  ].freeze

  def setup
    @instance = Inferno::Models::TestingInstance.new(url: 'http://www.example.com', base_url: 'http://localhost:4567', selected_module: 'quality_reporting')
    @ndjson_service = Inferno::NDJSONServiceFactory.create_service(Inferno::NDJSON_SERVICE_TYPE, @instance)
    @ndjson_result = @ndjson_service.generate_url_and_params(BUNDLES.map { |p| File.expand_path p, __dir__ })
  end

  def test_generated_ndjson
    # ndjson file should be created
    assert File.file?(@ndjson_result.output_file_path)

    # Number of lines in the ndjson file should match the number of bundles we provide
    file = File.open(@ndjson_result.output_file_path)
    assert file.readlines.size == BUNDLES.length
  end

  def test_generated_url
    # Service should generate a valid URI
    # NOTE: this is the only asssertion that makes sense in an Inferno unit test context
    # The server is responsible for actually GETting this url, and SHOULD tell the client if it gets a 404
    assert valid_uri?(@ndjson_result.url)
  end

  def test_file_not_exists
    # Should throw an exception
    @ndjson_service.generate_url_and_params('./this/does/not/exist')
    assert false
  rescue StandardError
    assert true
  end

  def test_generated_params
    expected_params = {
      'inputFormat': 'application/fhir+ndjson',
      'inputSource': 'http://www.example.com',
      'storageDetail': {
        'type': 'https'
      },
      'input': [{
        'type': 'Bundle',
        'url': @ndjson_result.url
      }]
    }

    assert_equal(@ndjson_result.params, expected_params)
  end
end
