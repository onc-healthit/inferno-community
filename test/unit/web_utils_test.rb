# frozen_string_literal: true

require_relative '../test_helper'

class WebUtilsTest < MiniTest::Test
  REQUEST_HEADERS = {
    'Accept' => '*/*',
    'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
    'Host' => 'www.example.com'
  }.freeze

  def test_retry_till_timeout_retry_specified
    # 3 second timeout
    retry_timeout = 3
    WebMock.reset!
    # specify requesting server to retry after 1 second
    stub_request(:get, 'http://www.example.com/Patient/')
      .with(headers: REQUEST_HEADERS)
      .to_return(
        headers: { 'retry_after' => 1 },
        status: 429
      )
    start_time = Time.now
    client = FHIR::Client.new('http://www.example.com/')
    Inferno::WebUtils.get_with_retry('http://www.example.com/Patient/', retry_timeout, client)
    elapsed_time = (Time.now - start_time).floor

    assert_equal(retry_timeout, elapsed_time)
  end

  def test_retry_till_timeout_retry_unspecified
    # 3 second timeout
    retry_timeout = 2
    WebMock.reset!
    # specify requesting server to retry after 1 second
    stub_request(:get, 'http://www.example.com/Patient/')
      .with(headers: REQUEST_HEADERS)
      .to_return(
        status: 429
      )
    start_time = Time.now
    client = FHIR::Client.new('http://www.example.com/')
    Inferno::WebUtils.get_with_retry('http://www.example.com/Patient/', retry_timeout, client)
    elapsed_time = (Time.now - start_time).floor

    assert_equal(retry_timeout, elapsed_time)
  end

  def test_no_retry_for_200_response
    WebMock.reset!
    # specify requesting server to retry after 1 second
    stub_request(:get, 'http://www.example.com/Patient/')
      .with(headers: REQUEST_HEADERS)
      .to_return(
        status: 200
      )
    start_time = Time.now
    client = FHIR::Client.new('http://www.example.com/')
    Inferno::WebUtils.get_with_retry('http://www.example.com/Patient/', 1, client)
    elapsed_time = (Time.now - start_time).floor
    assert(elapsed_time <= 1)
  end
end
