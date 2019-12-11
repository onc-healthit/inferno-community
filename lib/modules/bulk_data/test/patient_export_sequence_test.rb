# frozen_string_literal: true

require_relative '../../../../test/test_helper'

describe Inferno::Sequence::BulkDataExportSequence do
  before do
    @sequence_class = Inferno::Sequence::BulkDataExportSequence

    @instance = Inferno::Models::TestingInstance.create(
      url: 'http://www.example.com',
      bulk_access_token: 99_897_979
    )

    @instance.instance_variable_set(:'@module', OpenStruct.new(fhir_version: 'stu3'))

    @client = FHIR::Client.new(@instance.url)

    @file_request_headers = { accept: 'application/fhir+ndjson',
                              authorization: "Bearer #{@instance.bulk_access_token}" }

    @patient_file_location = 'http://www.example.com/patient_export.ndjson'
    @condition_file_location = 'http://www.example.com/condition_export.ndjson'

    @patient_export = load_fixture_with_extension('bulk_data_patient.ndjson')
    @condition_export = load_fixture_with_extension('bulk_data_condition.ndjson')

    @complete_status = {
      'transactionTime' => '2019-08-01',
      'request' => '[base]/Patient/$export?_type=Patient,Condition',
      'requiresAccessToken' => 'true',
      'output' => [
        { 'type' => 'Patient', 'url' => @patient_file_location },
        { 'type' => 'Condition', 'url' => @condition_file_location }
      ],
      'error' => 'error'
    }
  end

  describe 'read output tests' do
    before do
      @sequence = @sequence_class.new(@instance, @client)
    end

    it 'succeeds when output is valid' do
      stub_request(:get, @patient_file_location)
        .with(headers: @file_request_headers)
        .to_return(
          status: 200,
          headers: { content_type: 'application/fhir+ndjson' },
          body: @patient_export
        )

      stub_request(:get, @condition_file_location)
        .with(headers: @file_request_headers)
        .to_return(
          status: 200,
          headers: { content_type: 'application/fhir+ndjson' },
          body: @condition_export
        )

      @sequence.check_all_files(@complete_status['output'], 1)
    end

    it 'checks all output items' do
      stub_request(:get, @patient_file_location)
        .with(headers: @file_request_headers)
        .to_return(
          status: 200,
          headers: { content_type: 'application/fhir+ndjson' },
          body: @patient_export
        )

      assert_raises(WebMock::NetConnectNotAllowedError) do
        @sequence.check_all_files(@complete_status['output'], 1)
      end
    end

    it 'fails when content-type is invalid' do
      stub_request(:get, @patient_file_location)
        .with(headers: @file_request_headers)
        .to_return(
          status: 200,
          headers: { content_type: 'application/fhir+text' },
          body: @patient_export
        )

      error = assert_raises(Inferno::AssertionException) do
        @sequence.check_file_request(@complete_status['output'], 0, 1)
      end

      assert_match(/Expected content-type/, error.message)
    end
  end

  describe 'read NDJSON file tests' do
    before do
      @sequence = @sequence_class.new(@instance, @client)
    end

    it 'succeeds when NDJSON is valid' do
      @sequence.check_ndjson(@patient_export, 'Patient', 3)
    end

    it 'succeeds when lines_to_validate is nil' do
      @sequence.check_ndjson(@patient_export, 'Patient', nil)
    end

    it 'succeeds when lines_to_validate is less than 1' do
      @sequence.check_ndjson(@patient_export, 'Patient', -1)
    end

    it 'succeeds when lines_to_validate is decimal' do
      @sequence.check_ndjson(@patient_export, 'Patient', 0.5)
    end

    it 'succeeds when lines_to_validate is greater than lines of output file' do
      @sequence.check_ndjson(@patient_export, 'Patient', 100)
    end

    it 'fails when output file type is different from resource type' do
      error = assert_raises(Inferno::AssertionException) do
        @sequence.check_ndjson(@patient_export, 'Condition', 3)
      end

      assert_match(/^Resource type/, error.message)
    end

    it 'fails when output file has invalid resource' do
      invalid_patient_export = @patient_export.sub('"male"', '"001"')

      error = assert_raises(Inferno::AssertionException) do
        @sequence.check_ndjson(invalid_patient_export, 'Patient', 3)
      end

      assert_match(/invalid codes \[\\"001\\"\]/, error.message)
    end

    it 'succeeds when validate first line in output file having invalid resource' do
      invalid_patient_export = @patient_export.sub('"male"', '"001"')
      @sequence.check_ndjson(invalid_patient_export, 'Patient', 1)
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
    client.use_stu3
    client.default_json
    @sequence = Inferno::Sequence::BulkDataPatientExportSequence.new(@instance, client, true)
    @sequence.run_all_kick_off_tests = true
  end

  def include_export_stub_no_token
    headers = @export_request_headers.clone
    headers.delete(:authorization)

    stub_request(:get, 'http://www.example.com/Patient/$export')
      .with(headers: headers)
      .to_return(
        status: 401
      )
  end

  def include_export_stub(status_code: 202,
                          response_headers: { content_location: @content_location })
    stub_request(:get, 'http://www.example.com/Patient/$export')
      .with(headers: @export_request_headers)
      .to_return(
        status: status_code,
        headers: response_headers
      )
  end

  def include_export_stub_type_patient(status_code: 202,
                                       response_headers: { content_location: @content_location })
    stub_request(:get, 'http://www.example.com/Patient/$export?_type=Patient')
      .with(headers: @export_request_headers)
      .to_return(
        status: status_code,
        headers: response_headers
      )
  end

  def include_export_stub_type_patient_since_2019(status_code: 202,
                                                  response_headers: { content_location: @content_location })
    stub_request(:get, 'http://www.example.com/Patient/$export?_since=2019-01-01&_type=Patient')
      .with(headers: @export_request_headers)
      .to_return(
        status: status_code,
        headers: response_headers
      )
  end

  def include_export_stub_outputformat_application_fhir_ndjson(status_code: 202,
                                                               response_headers: { content_location: @content_location })
    stub_request(:get, 'http://www.example.com/Patient/$export?_outputFormat=application/fhir%2Bndjson')
      .with(headers: @export_request_headers)
      .to_return(
        status: status_code,
        headers: response_headers
      )
  end

  def include_export_stub_outputformat_application_ndjson(status_code: 202,
                                                          response_headers: { content_location: @content_location })
    stub_request(:get, 'http://www.example.com/Patient/$export?_outputFormat=application/ndjson')
      .with(headers: @export_request_headers)
      .to_return(
        status: status_code,
        headers: response_headers
      )
  end

  def include_export_stub_outputformat_ndjson(status_code: 202,
                                              response_headers: { content_location: @content_location })
    stub_request(:get, 'http://www.example.com/Patient/$export?_outputFormat=ndjson')
      .with(headers: @export_request_headers)
      .to_return(
        status: status_code,
        headers: response_headers
      )
  end

  def include_export_stub_type_patient_not_supports(status_code: 400,
                                                    response_headers: { content_location: @content_location })

    stub_request(:get, 'http://www.example.com/Patient/$export?_type=Patient')
      .with(headers: @export_request_headers)
      .to_return(
        status: status_code,
        headers: response_headers
      )
  end

  def include_export_stub_invalid_accept
    headers = @export_request_headers.clone
    headers[:accept] = 'application/fhir+xml'

    stub_request(:get, 'http://www.example.com/Patient/$export')
      .with(headers: headers)
      .to_return(
        status: 400
      )
  end

  def include_export_stub_invalid_prefer
    headers = @export_request_headers.clone
    headers[:prefer] = 'return=representation'

    stub_request(:get, 'http://www.example.com/Patient/$export')
      .with(headers: headers)
      .to_return(
        status: 400
      )
  end

  def include_export_stub_invalid_type
    stub_request(:get, 'http://www.example.com/Patient/$export?_type=UnknownResource')
      .with(headers: @export_request_headers)
      .to_return(
        status: 400
      )
  end

  def include_export_stub_invalid_since
    stub_request(:get, 'http://www.example.com/Patient/$export?_since=2018-13-13&_type=Patient')
      .with(headers: @export_request_headers)
      .to_return(
        status: 400
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

  def include_file_request_stub(response_headers: { content_type: 'application/fhir+ndjson' })
    stub_request(:get, @file_location)
      .with(headers: @file_request_headers)
      .to_return(
        status: 200,
        headers: response_headers,
        body: @patient_export
      )
  end

  def include_delete_request_stub
    stub_request(:delete, @content_location)
      .to_return(
        status: 202
      )
  end

  def test_all_pass
    WebMock.reset!

    include_export_stub_no_token
    include_export_stub
    include_export_stub_invalid_accept
    include_export_stub_invalid_prefer
    include_export_stub_type_patient
    include_export_stub_invalid_type
    include_export_stub_type_patient_since_2019
    include_export_stub_invalid_since
    include_export_stub_outputformat_application_fhir_ndjson
    include_export_stub_outputformat_application_ndjson
    include_export_stub_outputformat_ndjson
    include_status_check_stub
    include_file_request_stub
    include_delete_request_stub

    sequence_result = @sequence.start
    failures = sequence_result.failures

    assert failures.empty?, "All tests should pass. First error: #{failures&.first&.message}"
    assert !sequence_result.skip?, 'No tests should be skipped.'
    assert sequence_result.pass?, 'The sequence should be marked as pass.'
  end

  def test_export_type_patient_skip_not_supports
    WebMock.reset!

    include_export_stub_type_patient_not_supports

    assert_raises Inferno::SkipException do
      @sequence.check_export_kick_off(search_params: { '_type' => 'Patient' })
    end
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

  def test_output_file_fail_unmached_type
    search_params = { '_type' => 'Condition' }
    assert_raises Inferno::AssertionException do
      @sequence.assert_output_has_correct_type(@complete_status['output'], search_params)
    end
  end
end
