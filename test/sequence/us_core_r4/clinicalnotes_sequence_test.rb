# frozen_string_literal: true

require_relative '../../test_helper'

class USCoreR4ClinicalNotesSequenceTest < MiniTest::Test
  def setup
    @patient_id = 1234
    @docref_bundle = FHIR.from_contents(load_fixture(:us_core_r4_clinicalnotes_docref_bundle))
    @diagrpt_bundle = FHIR.from_contents(load_fixture(:us_core_r4_clinicalnotes_diagrpt_bundle))

    @instance = Inferno::Models::TestingInstance.new(
      url: 'http://www.example.com',
      client_name: 'Inferno',
      base_url: 'http://localhost:4567',
      client_endpoint_key: Inferno::SecureRandomBase62.generate(32),
      client_id: SecureRandom.uuid,
      selected_module: 'us_core_r4',
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

    set_resource_support(@instance, 'DocumentReference')

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
    @sequence = Inferno::Sequence::USCoreR4ClinicalNotesSequence.new(@instance, client, true)
  end

  def full_sequence_stubs
    WebMock.reset!

    # Search Clincal Notes
    stub_request(:get, "http://www.example.com/DocumentReference?category=clinical-note&patient=#{@patient_id}")
      .with(headers: @request_headers)
      .to_return(
        status: 200,
        body: @docref_bundle.to_json,
        headers: { content_type: 'application/fhir+json; charset=UTF-8' }
      )

    # Search Cardiology report
    stub_request(:get, "http://www.example.com/DiagnosticReport?category=http://loinc.org|LP29708-2&patient=#{@patient_id}")
      .with(headers: @request_headers)
      .to_return(
        status: 200,
        body: @diagrpt_bundle.to_json,
        headers: { content_type: 'application/fhir+json; charset=UTF-8' }
      )

    # Search Pathology report
    stub_request(:get, "http://www.example.com/DiagnosticReport?category=http://loinc.org|LP7839-6&patient=#{@patient_id}")
      .with(headers: @request_headers)
      .to_return(
        status: 200,
        body: @diagrpt_bundle.to_json,
        headers: { content_type: 'application/fhir+json; charset=UTF-8' }
      )

    # Search Cardiology report
    stub_request(:get, "http://www.example.com/DiagnosticReport?category=http://loinc.org|LP29684-5&patient=#{@patient_id}")
      .with(headers: @request_headers)
      .to_return(
        status: 200,
        body: @diagrpt_bundle.to_json,
        headers: { content_type: 'application/fhir+json; charset=UTF-8' }
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
end
