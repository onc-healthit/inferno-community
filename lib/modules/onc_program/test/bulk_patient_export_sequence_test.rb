# frozen_string_literal: true

require_relative '../../../../test/test_helper'

describe Inferno::Sequence::BulkDataPatientExportSequence do
  before do
    @content_location = 'http://www.example.com/status'
    @file_location = 'http://www.example.com/patient_export.ndjson'

    @sequence_class = Inferno::Sequence::BulkDataPatientExportSequence

    @instance = Inferno::Models::TestingInstance.create(
      url: 'http://www.example.com',
      bulk_url: 'https://www.example.com/bulk',
      bulk_access_token: 99_897_979
    )

    @instance.instance_variable_set(:'@module', OpenStruct.new(fhir_version: 'r4'))

    @client = FHIR::Client.new(@instance.url)

    @export_request_headers = { accept: 'application/fhir+json',
                                prefer: 'respond-async',
                                authorization: "Bearer #{@instance.bulk_access_token}" }

    @status_request_headers = { accept: 'application/json',
                                authorization: "Bearer #{@instance.bulk_access_token}" }
  end

  describe 'endpoint TLS tests' do
    before do
      @sequence = @sequence_class.new(@instance, @client)
      @test = @sequence_class[:bulk_endpoint_tls]
    end

    it 'fails when the auth endpoint does not support tls' do
      @instance.bulk_url = 'http://www.example.com/bulk'

      error = assert_raises(Inferno::AssertionException) do
        @sequence.run_test(@test)
      end

      assert_match(/^URI is not HTTPS/, error.message)
    end

    it 'succeeds when TLS 1.2 is supported' do
      stub_request(:get, @instance.bulk_url)
        .to_return(status: 200).then
        .to_raise(StandardError)

      @sequence.run_test(@test)
    end
  end

  describe 'CapabilityStatment tests' do
    before do
      @sequence = @sequence_class.new(@instance, @client)
      @headers = { accept: 'application/fhir+json' }
      @conformance = load_json_fixture('bulk_data_conformance')
    end

    it 'fail if status code is not 200' do
      stub_request(:get, @instance.bulk_url + '/metadata')
        .with(headers: @headers)
        .to_return(status: 400)

      error = assert_raises(Inferno::AssertionException) do
        @sequence.check_capability_statement
      end

      assert error.message == 'Bad response code: expected 200, 201, but found 400. '
    end

    it 'fail if CapabilityStatement does not declare Group resoure' do
      @conformance['rest'][0]['resource'].delete_at(0)
      stub_request(:get, @instance.bulk_url + '/metadata')
        .with(headers: @headers)
        .to_return(
          status: 200,
          body: @conformance.to_json
        )

      error = assert_raises(Inferno::AssertionException) do
        @sequence.check_capability_statement
      end

      assert error.message == 'Server CapabilityStatement did not declare support for export operation in Group resource.'
    end

    it 'fail if CapabilityStatement does not declare operation in Group resoure' do
      @conformance['rest'][0]['resource'][0].delete('operation')
      stub_request(:get, @instance.bulk_url + '/metadata')
        .with(headers: @headers)
        .to_return(
          status: 200,
          body: @conformance.to_json
        )

      error = assert_raises(Inferno::AssertionException) do
        @sequence.check_capability_statement
      end

      assert error.message == 'Server CapabilityStatement did not declare support for export operation in Group resource.'
    end

    it 'fail if CapabilityStatement does not declare export in Group resoure' do
      @conformance['rest'][0]['resource'][0]['operation'].delete_at(0)
      stub_request(:get, @instance.bulk_url + '/metadata')
        .with(headers: @headers)
        .to_return(
          status: 200,
          body: @conformance.to_json
        )

      error = assert_raises(Inferno::AssertionException) do
        @sequence.check_capability_statement
      end

      assert error.message == 'Server CapabilityStatement did not declare support for export operation in Group resource.'
    end

    it 'pass if CapabilityStatement declares export in Group resoure' do
      stub_request(:get, @instance.bulk_url + '/metadata')
        .with(headers: @headers)
        .to_return(
          status: 200,
          body: @conformance.to_json
        )

      @sequence.check_capability_statement
    end
  end

  describe 'requires access token tests' do
    before do
      @sequence = @sequence_class.new(@instance, @client)

      @complete_status = {
        'transactionTime' => '2019-08-01',
        'request' => '[base]/Patient/$export?_type=Patient,Observation',
        'requiresAccessToken' => 'true',
        'output' => [{ 'type' => 'Patient', 'url' => @file_location }],
        'error' => 'error'
      }
    end

    it 'fails when missing requiresAccessToken' do
      @complete_status.delete('requiresAccessToken')

      error = assert_raises(Inferno::AssertionException) do
        @sequence.assert_requires_access_token(@complete_status)
      end

      assert error.message == 'Bulk Data file server access SHALL require access token.'
    end

    it 'fails when requiresAccessToken is false' do
      @complete_status['requiresAccessToken'] = 'false'

      error = assert_raises(Inferno::AssertionException) do
        @sequence.assert_requires_access_token(@complete_status)
      end

      assert error.message == 'Bulk Data file server access SHALL require access token.'
    end

    it 'skips when requiresAccessToken is false and disable_bulk_data_require_access_token_test is true' do
      @instance.disable_bulk_data_require_access_token_test = true
      @complete_status['requiresAccessToken'] = 'false'

      error = assert_raises(Inferno::OmitException) do
        @sequence.assert_requires_access_token(@complete_status)
      end

      assert error.message == 'Require Access Token Test has been disabled by configuration.'
    end

    it 'succeeds when requiresAccessToken is true' do
      @sequence.assert_requires_access_token(@complete_status)
    end
  end

  describe 'delete request tests' do
    before do
      @sequence = @sequence_class.new(@instance, @client)
      @test = @sequence_class[:bulk_data_delete_test]
      @headers = { accept: 'application/json' }
    end

    it 'fails when server returns 200' do
      stub_request(:get, @instance.bulk_url + '/Patient/$export')
        .with(headers: @export_request_headers)
        .to_return(
          status: 202,
          headers: { content_location: @content_location }
        )

      stub_request(:delete, @content_location)
        .with(headers: @status_request_headers)
        .to_return(
          status: 200
        )

      error = assert_raises(Inferno::AssertionException) do
        @sequence.run_test(@test)
      end

      assert error.message == 'Bad response code: expected 202, but found 200'
    end
  end
end

class BulkDataPatientExportSequenceTest < MiniTest::Test
  def setup
    @content_location = 'http://www.example.com/status'
    @file_location = 'http://www.example.com/patient_export.ndjson'

    @complete_status = {
      'transactionTime' => '2019-08-01',
      'request' => '[base]/Patient/$export?_type=Patient,Observation',
      'requiresAccessToken' => 'true',
      'output' => [{ 'type' => 'Patient', 'url' => @file_location }],
      'error' => 'error'
    }

    @instance = Inferno::Models::TestingInstance.new(
      url: 'http://www.example.com',
      bulk_url: 'https://www.example.com/bulk',
      client_name: 'Inferno',
      base_url: 'http://localhost:4567',
      client_endpoint_key: Inferno::SecureRandomBase62.generate(32),
      client_id: SecureRandom.uuid,
      selected_module: 'bulk_data',
      oauth_authorize_endpoint: 'http://oauth_reg.example.com/authorize',
      oauth_token_endpoint: 'http://oauth_reg.example.com/token',
      scopes: 'launch openid patient/*.* profile',
      bulk_access_token: 99_897_979
    )

    @instance.instance_variable_set(:'@module', OpenStruct.new(fhir_version: 'r4'))

    @instance.save!

    @export_request_headers = { accept: 'application/fhir+json',
                                prefer: 'respond-async',
                                authorization: "Bearer #{@instance.bulk_access_token}" }

    @export_request_headers_no_token = { accept: 'application/fhir+json', prefer: 'respond-async' }

    @status_request_headers = { accept: 'application/json',
                                authorization: "Bearer #{@instance.bulk_access_token}" }

    @file_request_headers = { accept: 'application/fhir+ndjson',
                              authorization: "Bearer #{@instance.bulk_access_token}" }

    @patient_export = load_fixture_with_extension('bulk_data_patient.ndjson')

    @search_params = { '_type' => 'Patient' }

    client = FHIR::Client.new(@instance.url)
    client.default_json
    @sequence = Inferno::Sequence::BulkDataPatientExportSequence.new(@instance, client, true)
    @sequence.run_all_kick_off_tests = true

    @operation_outcome = load_json_fixture('bulk_data_operation_outcome')

    @conformance = load_json_fixture('bulk_data_conformance')
  end

  def include_tls_stub
    stub_request(:get, @instance.bulk_url)
  end

  def include_metadata_stub
    url = @instance.bulk_url + '/metadata'
    stub_request(:get, url)
      .with(headers: { accept: 'application/fhir+json' })
      .to_return(
        status: 200,
        body: @conformance.to_json
      )
  end

  def include_export_stub_no_token
    headers = @export_request_headers.clone
    headers.delete(:authorization)

    stub_request(:get, 'https://www.example.com/bulk/Patient/$export')
      .with(headers: headers)
      .to_return(
        status: 401
      )
  end

  def include_export_stub(status_code: 202,
                          response_headers: { content_location: @content_location })
    stub_request(:get, 'https://www.example.com/bulk/Patient/$export')
      .with(headers: @export_request_headers)
      .to_return(
        status: status_code,
        headers: response_headers
      )
  end

  def include_export_stub_invalid_accept
    headers = @export_request_headers.clone
    headers[:accept] = 'application/fhir+xml'

    stub_request(:get, 'https://www.example.com/bulk/Patient/$export')
      .with(headers: headers)
      .to_return(
        status: 400,
        headers: { content_type: 'application/json' },
        body: @operation_outcome.to_json
      )
  end

  def include_export_stub_invalid_prefer
    headers = @export_request_headers.clone
    headers[:prefer] = 'return=representation'

    stub_request(:get, 'https://www.example.com/bulk/Patient/$export')
      .with(headers: headers)
      .to_return(
        status: 400,
        headers: { content_type: 'application/json' },
        body: @operation_outcome.to_json
      )
  end

  def include_status_check_stub(status_code: 200,
                                response_headers: { content_type: 'application/json' },
                                response_body: @complete_status)
    stub_request(:get, @content_location)
      .with(headers: @status_request_headers)
      .to_return(
        status: status_code,
        headers: response_headers,
        body: response_body.to_json
      )
  end

  def include_delete_stub(status_code: 202)
    stub_request(:delete, @content_location)
      .with(headers: @status_request_headers)
      .to_return(
        status: status_code
      )
  end

  def test_all_pass
    WebMock.reset!

    include_tls_stub
    include_metadata_stub
    include_export_stub_no_token
    include_export_stub
    include_export_stub_invalid_accept
    include_export_stub_invalid_prefer
    include_status_check_stub
    include_delete_stub

    sequence_result = @sequence.start
    failures = sequence_result.failures

    assert failures.empty?, "All tests should pass. First error: #{failures&.first&.message}"
    assert !sequence_result.skip?, 'No tests should be skipped.'
    assert sequence_result.pass?, 'The sequence should be marked as pass.'
  end

  def test_export_fail_wrong_status
    WebMock.reset!

    include_export_stub(status_code: 200)

    assert_raises Inferno::AssertionException do
      @sequence.check_export_kick_off
    end
  end

  def test_export_fail_no_content_location
    WebMock.reset!

    include_export_stub(response_headers: {})

    assert_raises Inferno::AssertionException do
      @sequence.check_export_kick_off
    end
  end

  def test_status_check_skip_no_content_location
    assert_raises Inferno::SkipException do
      @sequence.check_export_status('')
    end
  end

  def test_status_check_skip_timeout
    WebMock.reset!
    stub_request(:get, @content_location)
      .with(headers: @status_request_headers)
      .to_return(
        status: 202,
        headers: { content_type: 'application/json', 'retry-after': '1' }
      )

    assert_raises Inferno::SkipException do
      @sequence.check_export_status(@content_location, timeout: 1)
    end
  end

  def test_status_check_fail_wrong_status_code
    WebMock.reset!

    include_status_check_stub(status_code: 201)

    assert_raises Inferno::AssertionException do
      @sequence.check_export_status(@content_location)
    end
  end

  def test_status_check_fail_no_output
    WebMock.reset!

    response_body = @complete_status.clone
    response_body.delete('output')

    include_status_check_stub(response_body: response_body)

    assert_raises Inferno::AssertionException do
      @sequence.check_export_status(@content_location)
    end
  end

  def test_status_check_fail_invalid_response_header
    WebMock.reset!

    include_status_check_stub(response_headers: { content_type: 'application/xml' })

    assert_raises Inferno::AssertionException do
      @sequence.check_export_status(@content_location)
    end
  end

  def test_output_file_fail_empty_output
    output = []

    assert_raises Inferno::AssertionException do
      @sequence.assert_output_has_type_url(output)
    end
  end

  def test_output_file_fail_no_url
    output = [{ 'type' => 'Patient', 'count' => 1 }]

    assert_raises Inferno::AssertionException do
      @sequence.assert_output_has_type_url(output)
    end
  end
end
