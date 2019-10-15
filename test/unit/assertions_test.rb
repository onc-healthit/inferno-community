# frozen_string_literal: true

require File.expand_path '../test_helper.rb', __dir__

describe Inferno::Assertions do
  before do
    # Create an instance of an anonymous class to wrap Inferno's assertions
    # which collide/conflct with the tests methods
    @inferno_asserter = Class.new do
      include Inferno::Assertions
    end.new
  end
  MESSAGE = 'MESSAGE'
  DATA = 'DATA'

  describe '#assert' do
    it 'raises an AssertionException if test is falsy' do
      exception = assert_raises(Inferno::AssertionException) do
        @inferno_asserter.assert(false, MESSAGE, DATA)
      end

      assert_equal(exception.message, MESSAGE)
      assert_equal(exception.details, DATA)
    end

    it 'does not raise an exception if test is truthy' do
      @inferno_asserter.assert(true, MESSAGE, DATA)
    end
  end

  describe '#assert_equal' do
    it 'raises an AssertionException if its arguments are not equal' do
      exception = assert_raises(Inferno::AssertionException) do
        @inferno_asserter.assert_equal(1, 2, MESSAGE, DATA)
      end

      assert_equal(exception.message, MESSAGE + ' Expected: 1, but found: 2.')
      assert_equal(exception.details, DATA)
    end

    it 'does not raise an exception if its arguments are equal' do
      @inferno_asserter.assert_equal(1, 1, MESSAGE, DATA)
    end
  end

  describe '#assert_response_ok' do
    it 'raises an AssertionException for status codes other than 200 and 201' do
      bad_response = OpenStruct.new(code: 400)
      exception = assert_raises(Inferno::AssertionException) do
        @inferno_asserter.assert_response_ok(bad_response, MESSAGE)
      end

      assert exception.message.end_with? MESSAGE
    end

    it 'does not raise an exception for status codes 200 and 201' do
      [200, 201].each do |status|
        response = OpenStruct.new(code: status)
        @inferno_asserter.assert_response_ok(response, MESSAGE)
      end
    end
  end

  describe '#assert_response_accepted' do
    it 'raises an AssertionException for status codes other than 202' do
      bad_response = OpenStruct.new(code: 200)
      assert_raises(Inferno::AssertionException) do
        @inferno_asserter.assert_response_accepted(bad_response)
      end
    end

    it 'does not raise an exception for status code 202' do
      response = OpenStruct.new(code: 202)
      @inferno_asserter.assert_response_accepted(response)
    end
  end

  describe '#assert_response_unauthorized' do
    it 'raises an AssertionException for status codes other than 401 and 406' do
      bad_response = OpenStruct.new(code: 200)
      assert_raises(Inferno::AssertionException) do
        @inferno_asserter.assert_response_unauthorized(bad_response)
      end
    end

    it 'does not raise an exception for status codes 401 and 406' do
      [401, 406].each do |status|
        response = OpenStruct.new(code: status)
        @inferno_asserter.assert_response_unauthorized(response)
      end
    end
  end

  describe '#assert_response_bad_or_unauthorized' do
    it 'raises an AssertionException for status codes other than 400 and 401' do
      bad_response = OpenStruct.new(code: 200)
      exception = assert_raises(Inferno::AssertionException) do
        @inferno_asserter.assert_response_bad_or_unauthorized(bad_response)
      end

      assert_equal exception.message, 'Bad response code: expected 400 or 401, but found 200'
    end

    it 'does not raise an exception for status codes 400 and 401' do
      [400, 401].each do |status|
        response = OpenStruct.new(code: status)
        @inferno_asserter.assert_response_bad_or_unauthorized(response)
      end
    end
  end

  describe '#assert_response_bad' do
    it 'raises an AssertionException for status codes other than 400' do
      bad_response = OpenStruct.new(code: 200)
      assert_raises(Inferno::AssertionException) do
        @inferno_asserter.assert_response_bad(bad_response)
      end
    end

    it 'does not raise an exception for status code 400' do
      response = OpenStruct.new(code: 400)
      @inferno_asserter.assert_response_bad(response)
    end
  end

  describe '#assert_response_bad' do
    it 'raises an AssertionException when the response does not include a Bundle' do
      [nil, FHIR::OperationOutcome.new].each do |not_bundle|
        bad_response = OpenStruct.new(resource: not_bundle)
        assert_raises(Inferno::AssertionException) do
          @inferno_asserter.assert_bundle_response(bad_response)
        end
      end
    end

    it 'does not raise an exception when the response includes a Bundle' do
      [FHIR::Bundle.new, FHIR::DSTU2::Bundle.new].each do |bundle|
        response = OpenStruct.new(resource: bundle)
        @inferno_asserter.assert_bundle_response(response)
      end
    end
  end

  describe '#assert_response_content_type' do
    it 'raises an AssertionException when the content-type does not match' do
      bad_response = OpenStruct.new(response: { headers: { 'content-type' => 'ABC' } })
      assert_raises(Inferno::AssertionException) do
        @inferno_asserter.assert_response_content_type(bad_response, 'XYZ')
      end
    end

    it 'does not raise an exception when the content-type matches' do
      content_type = 'ABC'
      fhir_client_response = { response: { headers: { 'content-type' => content_type } } }
      rest_client_response = { headers: { content_type: content_type } }
      [fhir_client_response, rest_client_response].each do |response_hash|
        response = OpenStruct.new(response_hash)
        @inferno_asserter.assert_response_content_type(response, content_type)
      end
    end
  end

  describe '#assert_tls_1_2' do
    before do
      WebMock.reset!
    end

    it 'raises an error for non-https urls ' do
      url = 'http://www.example.com/'
      stub_request(:any, url)

      assert_raises(Inferno::AssertionException) do
        @inferno_asserter.assert_tls_1_2(url)
      end
    end

    it 'does not raise an error if the url supports TSL 1.2' do
      url = 'https://www.example.com/'
      stub_request(:any, url)

      @inferno_asserter.assert_tls_1_2(url)
    end
  end

  describe '#assert_deny_previous_tls' do
    it 'does not raise an error if the requests cause an error' do
      WebMock.reset!
      url = 'https://www.example.com/'
      stub_request(:any, url).to_raise(StandardError)
      @inferno_asserter.assert_deny_previous_tls(url)
    end
  end

  describe '#assert_valid_http_uri' do
    it 'raises on error for non-url strings' do
      non_url = 'abc'
      exception = assert_raises(Inferno::AssertionException) do
        @inferno_asserter.assert_valid_http_uri(non_url, MESSAGE)
      end

      assert_equal(exception.message, MESSAGE)
    end

    it 'does not raise an error for urls' do
      urls = ['http://www.example.com', 'https://www.example.com']
      urls.each do |url|
        @inferno_asserter.assert_valid_http_uri(url)
      end
    end
  end

  describe '#assert_operation_supported' do
    it 'raises an error when the operation is not supported' do
      operation = 'operation'
      capabilities = Minitest::Mock.new
      capabilities.expect :operation_supported?, false, [operation]

      assert_raises(Inferno::AssertionException) do
        @inferno_asserter.assert_operation_supported(capabilities, operation)
      end
    end

    it 'does not raise an error when teh operatin is supported' do
      operation = 'operation'
      capabilities = Minitest::Mock.new
      capabilities.expect :operation_supported?, true, [operation]

      @inferno_asserter.assert_operation_supported(capabilities, operation)
    end
  end

  describe '#assert_valid_conformance' do
    it 'raises an error when the conformance classes do not match' do
      def @inferno_asserter.versioned_conformance_class
        FHIR::DSTU2::Conformance
      end

      assert_raises(Inferno::AssertionException) do
        @inferno_asserter.assert_valid_conformance(FHIR::CapabilityStatement.new)
      end
    end

    it 'does not raise an error when the conformance classes match' do
      def @inferno_asserter.versioned_conformance_class
        FHIR::CapabilityStatement
      end

      @inferno_asserter.assert_valid_conformance(FHIR::CapabilityStatement.new)
    end
  end
end
