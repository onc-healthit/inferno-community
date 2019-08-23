# frozen_string_literal: true

require_relative '../../test_helper'

class BulkDataPatientExportSequenceTest < MiniTest::Test
  def setup
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

    @instance.resource_references << Inferno::Models::ResourceReference.new(
      resource_type: 'Patient',
      resource_id: @patient_id
    )

    @instance.supported_resources << Inferno::Models::SupportedResource.create(
      resource_type: 'DocumentReference',
      testing_instance_id: @instance.id,
      supported: true,
      read_supported: true
    )

    @request_headers = {
      'Accept' => 'application/fhir+json',
      'Accept-Charset' => 'utf-8',
      'Accept-Encoding' => 'gzip, deflate',
      'Authorization' => 'Bearer 99897979',
      'Host' => 'www.example.com',
      'User-Agent' => 'Ruby FHIR Client'
    }

    client = FHIR::Client.new(@instance.url)
    client.use_r4
    client.default_json
    @sequence = Inferno::Sequence::BulkDataPatientExportSequence.new(@instance, client, true)
  end

  def full_sequence_stubs
    WebMock.reset!

    # $export kick off
    stub_request(:get, 'http://www.example.com/Patient/$export')
      .with(headers: @request_headers)
      .to_return(
        status: 202,
        headers: { content_location: 'http://www.example.com' }
      )
  end

  def test_all_pass
    full_sequence_stubs

    sequence_result = @sequence.start
    failures = sequence_result.failures
    assert failures.empty?, "All tests should pass. First error: #{failures&.first&.message}"
    assert !sequence_result.skip?, 'No tests should be skipped.'
    assert sequence_result.pass?, 'The sequence should be marked as pass.'
  end

  def test_export_fail_wrong_status
    WebMock.reset!

    # $export kick off
    stub_request(:get, 'http://www.example.com/Patient/$export')
      .with(headers: @request_headers)
      .to_return(
        status: 200,
        headers: { content_location: 'http://www.example.com' }
      )

    sequence_result = @sequence.start
    failures = sequence_result.failures

    assert !failures.empty?, 'test_export_fail_wrong_status should fail'
  end

  def test_export_fail_no_content_location
    WebMock.reset!

    # $export kick off
    stub_request(:get, 'http://www.example.com/Patient/$export')
      .with(headers: @request_headers)
      .to_return(
        status: 202,
        headers: { content_type: 'application/fhir+json; charset=UTF-8' }
      )

    sequence_result = @sequence.start
    failures = sequence_result.failures

    assert !failures.empty?, 'test_export_fail_no_content_location should fail'
  end
end
