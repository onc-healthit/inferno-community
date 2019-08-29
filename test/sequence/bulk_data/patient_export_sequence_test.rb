# frozen_string_literal: true

require_relative '../../test_helper'

class BulkDataPatientExportSequenceTest < MiniTest::Test
  def setup
    @complete_status = {
      'transactionTime' => '2019-08-01',
      'request' => '[base]/Patient/$export?_type=Patient,Observation',
      'requiresAccessToken' => 'true',
      'output' => 'output',
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
      token: 99_897_979
    )

    @instance.save!

    @export_request_headers = { accept: 'application/fhir+json',
                                prefer: 'respond-async',
                                authorization: "Bearer #{@instance.token}" }

    @export_request_headers_no_token = { accept: 'application/fhir+json', prefer: 'respond-async' }

    @content_location = 'http://www.example.com/status'

    client = FHIR::Client.new(@instance.url)
    client.use_stu3
    client.default_json
    @sequence = Inferno::Sequence::BulkDataPatientExportSequence.new(@instance, client, true)

  def include_export_sub(code = 202, headers = { content_location: @content_location })
    stub_request(:get, 'http://www.example.com/Patient/$export')
      .with(headers: @export_request_headers_no_token)
      .to_return(
        status: 401
      )

    stub_request(:get, 'http://www.example.com/Patient/$export')
      .with(headers: @export_request_headers)
      .to_return(
        status: code,
        headers: headers
      )
  end

  # status check
  def include_status_check_sub(code = 200, response_body = @complete_status)
    stub_request(:get, @content_location)
      .with(headers: @status_request_headers)
      .to_return(
        status: code,
        headers: { content_type: 'application/json' },
        body: response_body.to_json
      )
  end

  def full_sequence_stubs
    WebMock.reset!

    include_export_sub
    include_status_check_sub
  end

  def test_all_pass
    WebMock.reset!

    include_export_sub

    sequence_result = @sequence.start
    failures = sequence_result.failures
    assert failures.empty?, "All tests should pass. First error: #{failures&.first&.message}"
    assert !sequence_result.skip?, 'No tests should be skipped.'
    assert sequence_result.pass?, 'The sequence should be marked as pass.'
  end

  def test_export_fail_wrong_status
    WebMock.reset!

    include_export_sub(200)

    sequence_result = @sequence.start
    assert !sequence_result.pass?, 'test_export_fail_no_content_location should pass with status code 200'
    assert sequence_result.failures.first.message.include?('202'), "assert message #{sequence_result.failures.first.message} is not expected for status code 200."
  end

  def test_export_fail_no_content_location
    WebMock.reset!

    include_export_sub(202, {})

    sequence_result = @sequence.start
    assert !sequence_result.pass?, 'test_export_fail_no_content_location should pass with empty header'
    assert sequence_result.failures.first.message.include?('Content-Location'), "assert message #{sequence_result.failures.first.message} is not expected for empty header."
  end

  def test_status_check_fail_wrong_status_code
    WebMock.reset!

    include_export_sub
    include_status_check_sub(201)

    sequence_result = @sequence.start
    assert !sequence_result.pass?, 'test_status_check_fail_wrong_status_code should fail'
  end

  def test_status_check_fail_no_output
    WebMock.reset!

    response_body = @complete_status.clone
    response_body.delete('output')

    include_export_sub
    include_status_check_sub(200, response_body)

    sequence_result = @sequence.start
    assert !sequence_result.pass?, 'test_status_check_fail_no_output should fail'
  end
end
